# Frappe / ERPNext Python Backend Review

Covers controllers, whitelisted APIs, hooks, ORM, performance, Jinja templates, background jobs, translations, and tests for Frappe v14+ / ERPNext.

---

## ORM & Database

### 🔴 Critical — SQL injection
See `references/security.md`. Any string interpolation inside `frappe.db.sql()` is an automatic finding.

### 🟠 Major — ORM misuse
- `frappe.get_doc()` when only one field is needed → use `frappe.db.get_value()`
- `frappe.db.sql()` when `frappe.get_all()` / `frappe.get_list()` would work
- `frappe.db.sql()` without `as_dict=True`, leading to fragile tuple indexing
- `doc.save()` inside a loop without a `frappe.db.commit()` strategy
- `frappe.db.set_value()` in a loop instead of a bulk update

### 🟡 Minor — query style
- `frappe.get_all()` without explicit `fields=` (fetches all fields)
- Not using `pluck=` when only one field is needed: `frappe.get_all("X", pluck="name")`
- `limit_page_length=0` without a comment explaining why all rows are needed
- Raw SQL where the ORM equivalent is cleaner

---

## Whitelisted APIs

### 🔴 Critical — permission bypass
```python
# BAD
@frappe.whitelist()
def delete_student(student_id):
    frappe.delete_doc("Student", student_id)

# GOOD
@frappe.whitelist()
def delete_student(student_id):
    frappe.has_permission("Student", "delete", throw=True)
    frappe.delete_doc("Student", student_id)
```
Every `@frappe.whitelist()` that reads or modifies data MUST have a permission check unless `allow_guest=True` is intentional and justified.

### 🟠 Major — API issues
- `@frappe.whitelist(allow_guest=True)` without clear justification — flag and ask why
- Whitelisted method doing too many things (>30 lines) — should be broken up
- Returning raw `frappe.db.sql()` results instead of sanitized dicts
- Missing input validation on parameters
- **Mass assignment**: `frappe.get_doc(json.loads(data)).insert()` where `data` is user-supplied — attacker can set `owner`, `docstatus`, `_user_tags`. Whitelist allowed fields explicitly.
- **Type coercion**: arguments arrive as strings from the HTTP layer. `if doc.qty > 0` where `qty` is a string is always true. Cast with `cint` / `flt`.
- Method modifies data but doesn't return meaningful confirmation

### 🟡 Minor — API style
- Missing docstring on whitelisted method
- Method name doesn't clearly describe the action
- Inconsistent return shape across related methods

### Flags & permissions
```python
# BAD — blanket bypass
frappe.flags.ignore_permissions = True
doc.save()

# ACCEPTABLE — scoped
frappe.flags.ignore_permissions = True
try:
    doc.save()
finally:
    frappe.flags.ignore_permissions = False

# BETTER — set on the doc itself
doc.flags.ignore_permissions = True
doc.save()
```
Flag any `frappe.flags.ignore_permissions = True` without a corresponding reset as 🟠 Major.

---

## Controller patterns

### Where logic belongs
- **`validate()`** — input validation, cross-field checks, permission-based field restrictions
- **`before_save()`** — computed fields, derived values, auto-population
- **`before_insert()`** — one-time setup, auto-naming
- **`on_submit()`** — side effects (ledger entries, notifications, linked docs)
- **`on_cancel()`** — reverse side effects cleanly
- **`on_trash()`** — pre-delete cleanup; never mutate `self` here without persisting (the doc is about to disappear)

### 🟠 Major
- Business logic in `__init__` instead of lifecycle hooks
- Side effects (emails, API calls, doc creation) in `validate()` — belong in `on_submit` / `after_insert`
- Heavy computations in `validate()` that should be in `before_save()`
- Missing `on_cancel()` when `on_submit()` creates linked documents
- `self.db_set("field", value)` inside `validate()` — `validate` runs before insert/update; either fires on a missing row or fights the upcoming save. Use plain assignment.
- `frappe.db.commit()` inside a controller method — let Frappe manage the transaction. Exception: long-running background jobs.
- Missing `frappe.throw` on invalid state — silent `return` lets bad data through

### 🟡 Minor — controller style
- Controller class with methods unrelated to the DocType lifecycle
- Super-long `validate()` that should be split into private methods
- Missing `super().validate()` call when overriding (unless intentional)

---

## Hooks & app structure

### `hooks.py`
- 🔴 `doc_events` handler pointing to a method that doesn't exist
- 🟠 `doc_events` with `*` wildcard without justification
- 🟠 `doc_events` registering a heavy function on `*` / `Doctype.*` — runs on every save of every doc
- 🟠 Fixtures listing transactional DocTypes (orders, invoices) — should not be fixtures
- 🟠 `scheduler_events` pointing to heavy functions without `frappe.enqueue`
- 🟠 `override_doctype_class` / `override_whitelisted_methods` overriding ERPNext core — high regression risk; flag and ask whether a hook or custom field would suffice
- 🟠 New `boot_session` work — runs on every page load; expensive checks belong in lazy endpoints
- 🟡 Missing `hooks.py` entries when new controllers have lifecycle methods

### App structure
- 🟠 Circular imports between modules
- 🟡 Python files outside the module folder structure
- 🟡 Utils file growing beyond 500 lines (suggest splitting)
- 🟡 `__init__.py` with non-trivial logic

---

## Performance

### 🟠 Major — N+1 / loop queries
```python
# BAD — N+1
students = frappe.get_all("Student", fields=["name"])
for s in students:
    enrollment = frappe.get_doc("Student Enrollment", {"student": s.name})  # one DB hit per student

# GOOD — batch
students = frappe.get_all("Student", fields=["name"])
names = [s.name for s in students]
enrollments = frappe.get_all(
    "Student Enrollment",
    filters={"student": ["in", names]},
    fields=["name", "student", "program"],
)
enrollment_map = {e.student: e for e in enrollments}
```
Flag any `frappe.get_doc`, `frappe.get_all`, or `frappe.db.sql` inside a `for` / `while` loop as 🟠 Major.

### 🟠 Major — other performance issues
- `frappe.get_doc()` when `frappe.db.get_value()` would do (loads full doc + child tables)
- Missing `limit_page_length` on `get_all` that could return thousands of rows
- Synchronous heavy work (PDF, bulk email, large report) not using `frappe.enqueue`
- `frappe.db.count()` with complex filters instead of a targeted SQL count
- Large file processing in the request thread instead of a background job

---

## Frappe v15 specifics

Flag these deprecated/outdated patterns:
- 🟠 `frappe.get_list` with `ignore_permissions=True` instead of proper role permissions
- 🟡 Old-style `frappe.client.get_list`
- 🟡 `frappe.get_doc` for read-only access — use `frappe.get_cached_doc` or `frappe.get_all`
- 🟡 `frappe.msgprint` for errors instead of `frappe.throw`
- 🟡 Setting `frappe.local.response` directly instead of returning from the whitelisted method
- 💡 No type hints on whitelisted method parameters (v15 encourages this)

---

## Jinja templates

### 🔴 Critical — XSS
See `references/security.md`. Always escape user-controlled content in `{{ }}`.

### 🟡 Minor — template style
- Complex Python logic in Jinja — move to controller / context
- Hardcoded styles in templates instead of CSS classes
- Missing `{% if %}` null checks on optional fields

---

## Background jobs & scheduling

- 🟠 `frappe.enqueue` with `now=True` in production code (defeats the purpose)
- 🟠 Scheduled job that could take >15 minutes without chunking
- 🟠 Missing idempotency — job that breaks if run twice
- 🟠 Job function not module-level / not importable — Frappe can't pickle it
- 🟠 Job mutates `frappe.local.user` or `frappe.flags` without restoring — leaks into other jobs in the same worker
- 🟠 `queue="short"` with `timeout > 60` — wrong queue. `short` is for ≤60s; use `default` (~300s) or `long` (~1500s)
- 🟡 `frappe.enqueue` without `queue` parameter (defaults to `default` which may be overloaded)
- 🟡 Missing `timeout` on long-running jobs

---

## Translations

- 🟡 User-facing strings not wrapped in `frappe._()` or `_()`
- 🟠 f-strings inside `_()` (silently breaks translation extraction):
  ```python
  # BAD
  frappe.throw(_(f"Student {name} not found"))
  # GOOD
  frappe.throw(_("Student {0} not found").format(name))
  ```

---

## Tests (`test_*.py`)

- 🟠 New API / controller change with no test added
- 🟠 Test relies on `Administrator` for permission-sensitive code path — passes locally, fails for real roles
- 🟠 Tests depend on data existing in the DB without setup
- 🟡 Missing teardown / cleanup
- 🟡 Test method without descriptive name
- 💡 Tests testing implementation details rather than behavior
- 💡 Missing edge-case tests for validation logic
