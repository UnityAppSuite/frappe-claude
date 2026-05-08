---
name: testing-patterns
description: How to write robust Frappe tests — FrappeTestCase, factories, mocking frappe.sendmail / external HTTP, permission tests, change_settings, anti-patterns to avoid. Use when writing or reviewing test_*.py files, designing test fixtures, or thinking about test isolation. The /frappe-test command runs tests; this skill teaches how to write them.
---

# Frappe Testing Patterns

Reference for writing maintainable tests in Frappe v14+. Focused on the patterns that hold up as your test suite grows past a few dozen tests — factory functions, fixture isolation, mocking, and the anti-patterns that cause flaky failures in CI.

## Which base class

```python
from frappe.tests.utils import FrappeTestCase
```

Use `FrappeTestCase` (not `unittest.TestCase`) for anything that touches Frappe — controllers, APIs, DB. It handles:
- Per-test transaction rollback (you don't need to clean up created docs in `tearDown`)
- `frappe.flags.in_test = True` (so production code can branch on test mode if needed)
- Test record loading from `test_records.json`
- Permission isolation (resets `frappe.session.user` between tests)

Use plain `unittest.TestCase` only for pure-Python helpers with no Frappe touchpoints (string utilities, math, etc.).

## File location and naming

```
my_app/
└── my_module/
    └── doctype/
        └── expense_claim/
            ├── expense_claim.py
            ├── expense_claim.js
            ├── expense_claim.json
            ├── test_expense_claim.py    ← convention
            └── test_records.json        ← optional: seed data for the suite
```

Frappe discovers tests by walking each app's `<module>/doctype/<doctype>/test_*.py`. For non-DocType tests (utilities, integrations), put them in `my_app/tests/` and Frappe still finds them.

Test methods must start with `test_`. Helper methods on the test class (factories, common assertions) should not — name them `_make_invoice`, `_assert_balanced`, etc.

## Test data lifecycle

### `test_records.json` — suite-level fixtures

```json
[
    {
        "doctype": "Customer",
        "customer_name": "_Test Customer Alpha",
        "customer_type": "Company",
        "territory": "_Test Territory"
    },
    {
        "doctype": "Item",
        "item_code": "_Test Item Widget",
        "item_name": "Widget",
        "stock_uom": "Nos"
    }
]
```

Loaded once per test run, available to every test in the file via `frappe.get_doc("Customer", "_Test Customer Alpha")`. Use the `_Test` prefix on names — it's the team convention so test data is visually distinct from production seed data.

`test_records.json` is loaded with `ignore_permissions=True`, so it can create docs the test user doesn't normally have access to.

### `setUp` vs `setUpClass`

```python
class TestExpenseClaim(FrappeTestCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        # Runs ONCE per test class. Use for read-only setup that won't be mutated.
        cls.approver_user = "_test_approver@example.com"
        cls.create_approver_if_missing()

    def setUp(self):
        # Runs before EACH test. Use for state that tests will mutate.
        # Don't put expensive setup here.
        frappe.set_user("Administrator")

    def tearDown(self):
        # Often unneeded — FrappeTestCase rolls back the transaction automatically.
        # Use only for things that escape the transaction (file writes, real HTTP).
        pass
```

Most tests need no `setUp` or `tearDown` at all — the per-test rollback handles it.

### Factory pattern

For docs that vary per test, write a `_make_<thing>` helper that takes overrides:

```python
class TestExpenseClaim(FrappeTestCase):
    def _make_expense_claim(self, **overrides):
        defaults = {
            "doctype": "Expense Claim",
            "employee": "_Test Employee Alpha",
            "expenses": [{
                "expense_type": "Travel",
                "amount": 100.0,
                "expense_date": frappe.utils.nowdate(),
            }],
        }
        defaults.update(overrides)
        doc = frappe.get_doc(defaults)
        doc.insert()
        return doc

    def test_total_calculation(self):
        claim = self._make_expense_claim(expenses=[
            {"expense_type": "Travel", "amount": 100.0, "expense_date": frappe.utils.nowdate()},
            {"expense_type": "Food", "amount": 50.0, "expense_date": frappe.utils.nowdate()},
        ])
        self.assertEqual(claim.total_claimed_amount, 150.0)

    def test_default_status(self):
        claim = self._make_expense_claim()
        self.assertEqual(claim.status, "Draft")
```

Factories should be **idempotent on the parts that don't change between tests**. The Customer and Item are seed data; only the Expense Claim is created per test.

## Permission tests

```python
def test_employee_cannot_approve_own_claim(self):
    # Set the user we're testing as
    frappe.set_user("alice@example.com")  # Employee role
    claim = self._make_expense_claim(employee="HR-EMP-Alice")

    # Try the privileged operation
    with self.assertRaises(frappe.PermissionError):
        from frappe.model.workflow import apply_workflow
        apply_workflow(claim, "Approve")

    # Reset before the next test (FrappeTestCase auto-resets, but explicit is safer)
    frappe.set_user("Administrator")

def test_manager_can_approve(self):
    self._make_employee("alice@example.com", roles=["Employee"])
    self._make_employee("bob@example.com", roles=["Employee", "Expense Approver"])

    frappe.set_user("alice@example.com")
    claim = self._make_expense_claim()
    apply_workflow(claim, "Submit")

    frappe.set_user("bob@example.com")
    apply_workflow(claim, "Approve")
    self.assertEqual(claim.workflow_state, "Approved")
```

Always reset to `Administrator` (or `Guest` for unauthenticated tests) explicitly — even though `FrappeTestCase` does it for you, it makes the intent obvious and protects against test ordering changes.

## Mocking external calls

Use `unittest.mock.patch` from the standard library. Frappe ships no special mocking framework.

### Mock `frappe.sendmail`

Most tests should not actually send mail. Patch it for the duration of the test:

```python
from unittest.mock import patch

class TestExpenseClaim(FrappeTestCase):
    @patch("frappe.sendmail")
    def test_approval_sends_notification(self, mock_sendmail):
        claim = self._make_expense_claim()
        apply_workflow(claim, "Approve")

        mock_sendmail.assert_called_once()
        call_kwargs = mock_sendmail.call_args.kwargs
        self.assertIn("approved", call_kwargs["subject"].lower())
        self.assertEqual(call_kwargs["recipients"], [claim.employee_email])
```

### Mock external HTTP

```python
@patch("requests.post")
def test_webhook_fires_on_submit(self, mock_post):
    mock_post.return_value.status_code = 200
    mock_post.return_value.json.return_value = {"received": True}

    claim = self._make_expense_claim()
    claim.submit()

    mock_post.assert_called_once()
    self.assertEqual(mock_post.call_args.args[0], "https://hooks.example.com/expense")
```

### Mock `frappe.publish_realtime`

```python
@patch("frappe.publish_realtime")
def test_progress_published_during_long_job(self, mock_publish):
    run_my_long_job(args)
    self.assertTrue(mock_publish.called)
    # Inspect call_args_list for ordering
```

## `frappe.flags.in_test`

Set automatically by `FrappeTestCase`. Use it sparingly in production code:

```python
def send_notification(recipient, message):
    if frappe.flags.in_test:
        # Skip real send during tests — but tests should mock frappe.sendmail directly anyway
        return
    frappe.sendmail(recipients=[recipient], message=message)
```

Prefer mocking the function in the test over branching on `in_test` in production code. Branching pollutes business logic with test concerns; mocking keeps the production path clean.

## `change_settings` context manager

For tests that depend on a Single doctype's setting:

```python
from frappe.tests.utils import change_settings

class TestStockNegative(FrappeTestCase):
    def test_negative_stock_blocked(self):
        # Default: should not allow negative stock
        with self.assertRaises(frappe.ValidationError):
            self._make_delivery_note_exceeding_stock()

    def test_negative_stock_allowed_when_setting_on(self):
        with change_settings("Stock Settings", {"allow_negative_stock": 1}):
            doc = self._make_delivery_note_exceeding_stock()
            self.assertEqual(doc.docstatus, 1)
        # Setting auto-restored on context exit
```

Settings are restored after the `with` block, even if the test fails. Don't manually save and restore — `change_settings` handles transactions correctly.

## Background job tests

By default, `frappe.enqueue` queues the job for a worker — but in tests, you want it to run synchronously:

```python
def test_nightly_sync_creates_records(self):
    from my_app.tasks import sync_external_data

    # Two options:

    # Option 1: call the function directly (preferred — tests the function in isolation)
    sync_external_data(account="ACC-001")

    # Option 2: enqueue with now=True (tests the wiring, runs in-process)
    frappe.enqueue("my_app.tasks.sync_external_data", now=True, account="ACC-001")

    # Verify side effects
    records = frappe.get_all("Sync Log", filters={"account": "ACC-001"})
    self.assertEqual(len(records), 1)
```

`now=True` does not actually go through Redis; it runs the function in the current process. Safe in tests.

## Test API endpoints

Whitelisted methods are just functions. Test them by importing and calling:

```python
def test_get_outstanding_returns_dict(self):
    from my_app.api import get_customer_outstanding

    result = get_customer_outstanding(customer="_Test Customer Alpha")

    self.assertIsInstance(result, dict)
    self.assertIn("outstanding", result)
    self.assertGreaterEqual(result["outstanding"], 0)

def test_api_blocks_guest(self):
    from my_app.api import get_customer_outstanding

    frappe.set_user("Guest")
    with self.assertRaises(frappe.PermissionError):
        get_customer_outstanding(customer="_Test Customer Alpha")
    frappe.set_user("Administrator")
```

For testing the HTTP layer (CSRF, query parsing, response serialization), use `frappe.tests.test_api` patterns or call through `frappe.client` — but most API logic tests don't need to go through HTTP.

## Coverage strategy

What to test:
- **`validate()` and lifecycle hooks** — every branch, especially the `frappe.throw` paths
- **`on_submit` / `on_cancel` side effects** — the linked docs, ledger entries, notifications
- **Whitelisted methods** — happy path + each `frappe.throw` + permission boundary
- **Custom queries** — especially anything with `frappe.db.sql` or aggregation
- **Complex calculations** — taxes, discounts, currency conversions
- **Permission boundaries** — at least one test per role per restricted action

What not to test:
- **Frappe internals** — don't test that `frappe.get_doc` works
- **Generated CRUD** — Frappe handles insert / update / delete; only test your overrides
- **Stylistic choices** — don't assert on field order, label casing, etc.
- **Implementation details** — assert on observable behavior, not internal method names. If you rename a private helper, the test should still pass.

A useful target: test every `frappe.throw` and every `if` branch in `validate` / `on_submit`. Coverage of pure data transformation is easy; coverage of error paths is what catches regressions.

## Anti-patterns to avoid

| Anti-pattern | Why it bites | What to do |
|--------------|--------------|------------|
| Test depends on prior test having run | Test ordering changes break the suite | Each test creates its own data via factories |
| Hardcoded user emails like `"badal@example.com"` | Breaks when run on a different machine | Use the `_Test` prefix or a fixture user |
| Asserting on auto-generated names (`SINV-2026-00001`) | Names change with naming series, year, prior data | Assert on `doc.name` existing, not on its value |
| `setUp` does expensive DB setup that all tests redo | Slow suite | Move shared setup to `setUpClass` |
| Test catches a generic `Exception` | Hides the real failure mode | Catch specific exceptions: `frappe.ValidationError`, `frappe.PermissionError` |
| `time.sleep` in tests | Flaky in CI | Mock time-dependent functions instead |
| Test creates docs with `ignore_permissions=True` everywhere | Hides permission bugs | Use `Administrator`; switch users explicitly when testing perms |
| Test commits to DB explicitly (`frappe.db.commit()`) | Breaks transaction rollback; pollutes DB across tests | Never call `commit()` in a test |
| `assertEqual(doc.status, "Submitted")` without first asserting `doc.docstatus == 1` | Status field can be set independently of submission | Assert on the lifecycle state, not just denormalized fields |

## Full example: controller test

```python
# my_app/expense/doctype/expense_claim/test_expense_claim.py
from unittest.mock import patch

import frappe
from frappe.tests.utils import FrappeTestCase
from frappe.model.workflow import apply_workflow


class TestExpenseClaim(FrappeTestCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls._ensure_user("alice@example.com", ["Employee"])
        cls._ensure_user("bob@example.com", ["Employee", "Expense Approver"])

    @staticmethod
    def _ensure_user(email, roles):
        if frappe.db.exists("User", email):
            return
        user = frappe.get_doc({
            "doctype": "User",
            "email": email,
            "first_name": email.split("@")[0].title(),
            "send_welcome_email": 0,
            "roles": [{"role": r} for r in roles],
        })
        user.insert(ignore_permissions=True)

    def _make_claim(self, **overrides):
        defaults = {
            "doctype": "Expense Claim",
            "employee": "_Test Employee Alpha",
            "expenses": [{
                "expense_type": "Travel",
                "amount": 100.0,
                "expense_date": frappe.utils.nowdate(),
            }],
        }
        defaults.update(overrides)
        doc = frappe.get_doc(defaults)
        doc.insert()
        return doc

    # ---- create / validate ----

    def test_total_is_sum_of_expenses(self):
        claim = self._make_claim(expenses=[
            {"expense_type": "Travel", "amount": 100.0, "expense_date": frappe.utils.nowdate()},
            {"expense_type": "Food", "amount": 50.0, "expense_date": frappe.utils.nowdate()},
        ])
        self.assertEqual(claim.total_claimed_amount, 150.0)

    def test_negative_amount_rejected(self):
        with self.assertRaises(frappe.ValidationError):
            self._make_claim(expenses=[
                {"expense_type": "Travel", "amount": -10.0, "expense_date": frappe.utils.nowdate()},
            ])

    def test_future_expense_date_rejected(self):
        future = frappe.utils.add_days(frappe.utils.nowdate(), 7)
        with self.assertRaises(frappe.ValidationError):
            self._make_claim(expenses=[
                {"expense_type": "Travel", "amount": 100.0, "expense_date": future},
            ])

    # ---- workflow / submit ----

    @patch("frappe.sendmail")
    def test_approve_submits_and_notifies(self, mock_sendmail):
        frappe.set_user("alice@example.com")
        claim = self._make_claim()
        apply_workflow(claim, "Submit")

        frappe.set_user("bob@example.com")
        apply_workflow(claim, "Approve")

        claim.reload()
        self.assertEqual(claim.workflow_state, "Approved")
        self.assertEqual(claim.docstatus, 1)
        mock_sendmail.assert_called()

        frappe.set_user("Administrator")

    def test_self_approval_blocked(self):
        frappe.set_user("bob@example.com")
        claim = self._make_claim(employee="HR-EMP-Bob")
        apply_workflow(claim, "Submit")

        with self.assertRaises(frappe.PermissionError):
            apply_workflow(claim, "Approve")

        frappe.set_user("Administrator")

    # ---- cancel ----

    def test_cancel_reverses_payment(self):
        # Create, approve, then cancel
        claim = self._make_claim()
        apply_workflow(claim, "Submit")
        apply_workflow(claim, "Approve")

        payment_name = frappe.db.get_value(
            "Payment Entry",
            {"reference_doctype": "Expense Claim", "reference_name": claim.name},
            "name",
        )
        self.assertIsNotNone(payment_name)

        claim.cancel()

        payment_status = frappe.db.get_value("Payment Entry", payment_name, "docstatus")
        self.assertEqual(payment_status, 2, "Payment should be cancelled")
```

## See also

- `/frappe-test` command — runs the tests this skill teaches you to write
- `server-scripts` skill — controller hooks (`validate`, `on_submit`, `on_cancel`) you'll be testing
- `references/frappe-python.md` (in `frappe-review` skill) — review-time checks for tests (test isolation, hardcoded users, missing tests for new APIs)
