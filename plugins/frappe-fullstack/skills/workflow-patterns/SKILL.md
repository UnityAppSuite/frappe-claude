---
name: workflow-patterns
description: Frappe Workflow design — multi-state document lifecycles, role-based transitions, state-scoped field permissions, workflow handlers, and the team's pragmatic deviations (Custom Field for workflow_state, db_set over apply_workflow, custom workflow DocTypes). Use when designing or modifying an approval flow, a state machine on a DocType, or anything involving Workflow / Workflow State / Workflow Transition.
---

# Frappe Workflow Patterns

Reference for designing Frappe workflows, aligned with the team's edu_quality conventions: `workflow_state` added via Custom Field in the customizations sub-app (not source DocType edits), pragmatic use of `db_set` over `apply_workflow` for programmatic transitions, and willingness to build a custom DocType + Page when stock Workflow doesn't fit.

## Team conventions

These are the rules the existing codebase follows. New workflows should follow them; deviations need a reason.

1. **Add `workflow_state` via Custom Field** in `sc_customizations` (or equivalent customizations sub-app), not by editing the source DocType JSON. Keeps customizations isolated from upstream apps.
2. **`Custom Field` JSON for `workflow_state`** uses these settings: `fieldtype: "Link"`, `options: "Workflow State"`, `default: "Approved"` (or your default state), `hidden: 1`, `no_copy: 1`, `allow_on_submit: 1`. See the example in `sc_customizations/custom_field/Fees-workflow_state.json`.
3. **Use `db_set("workflow_state", "X")` for programmatic transitions** in most code paths. Pragmatic — bypasses transition validation, runs no `condition`, fires no email — but matches what the codebase does today (e.g. `refund_request.py:208`, `scan_receipts.py:17`). Use `apply_workflow` only when you specifically want the role check + condition + notification.
4. **Always wrap `db_set` calls with `hasattr(doc, "workflow_state")`** as a defensive check. The Custom Field may not be applied in every site; the code should still work.
5. **When stock Workflow doesn't fit, build a custom workflow DocType** plus a Frappe Page for the UI. We have precedent: `Funnel Workflow` for student application funnel, `fee_workflow` Page for fee operations. Don't try to bend Workflow to fit funnels or multi-doc orchestration.

## When to use a stock Workflow

A stock Frappe Workflow is the right tool when **all** of these are true:
- The document moves through a fixed sequence of named states (Draft → Pending → Approved → ...).
- Different roles can move it between specific pairs of states.
- The "current state" is meaningful in the UI and reports.

Use a plain `Select` status field instead when:
- States are advisory rather than gating.
- Transitions don't need permission checks.
- You don't care who moved it from one state to another.

Build a **custom workflow DocType + Page** when:
- The workflow involves multiple linked documents (a funnel through Application → Enrollment → Fee Setup → Payment).
- The state transitions need a richer UI than the standard "Action" buttons (drag-and-drop, multi-select bulk actions, custom validation per stage).
- You need to track state changes as their own queryable records.

Don't use a Workflow alongside `is_submittable: 1` unless you understand both will run — the workflow controls visible state, but Frappe still tracks `docstatus` (0 / 1 / 2) underneath.

## Adding workflow_state via Custom Field

Create a Custom Field JSON in the customizations sub-app:

```json
{
    "doctype": "Custom Field",
    "name": "Fees-workflow_state",
    "dt": "Fees",
    "fieldname": "workflow_state",
    "label": "Workflow State",
    "fieldtype": "Link",
    "options": "Workflow State",
    "default": "Approved",
    "hidden": 1,
    "no_copy": 1,
    "allow_on_submit": 1,
    "module": "Sc Customizations",
    "creation": "2023-10-03 17:26:45.823538",
    "modified": "2023-10-03 07:22:09.967376",
    "modified_by": "Administrator"
}
```

File location: `sc_customizations/custom_field/{DocType}-workflow_state.json`. Register via fixtures in the customizations sub-app's `hooks.py`:

```python
fixtures = [
    {"dt": "Custom Field", "filters": [["module", "=", "Sc Customizations"]]}
]
```

**Why hidden by default:** the workflow state is shown by the workflow timeline UI; the field itself doesn't need to be visible on the form.

**Why `no_copy: 1`:** a copied document should start at the default state, not inherit the source's state.

**Why `allow_on_submit: 1`:** the field can be updated on submitted docs (otherwise approval transitions on a submitted doc would fail).

## Workflow anatomy

Workflows themselves are DocTypes — `Workflow`, `Workflow State`, `Workflow Action Master`, `Workflow Transition`. The Workflow doc lives in the database (created via the desk), exported with:

```bash
bench --site <site> export-fixtures
```

A workflow has these key fields:

| Field | What it does |
|-------|--------------|
| `document_type` | The DocType this workflow applies to |
| `workflow_state_field` | Fieldname holding the current state — the team uses `workflow_state` consistently |
| `is_active` | `1` to enable. Only one active workflow per DocType. |
| `send_email_alert` | `1` sends notifications to the next actor on transition |
| `states` | Child table of `Workflow Document State` |
| `transitions` | Child table of `Workflow Transition` |

### States — `Workflow Document State`

```json
{
  "state": "Pending Approval",
  "doc_status": "0",
  "allow_edit": "Manager",
  "update_field": "status",
  "update_value": "Pending"
}
```

| Field | Use |
|-------|-----|
| `state` | Name of the state — must match a `Workflow State` row (define those first) |
| `doc_status` | `"0"` (draft), `"1"` (submitted), `"2"` (cancelled) |
| `allow_edit` | Role allowed to edit fields while in this state. Other roles see read-only. |
| `update_field` / `update_value` | Optional: when the doc enters this state, set this field on the doc to this value. Useful for keeping a denormalized `status` field in sync with the workflow. |

### Transitions — `Workflow Transition`

```json
{
  "state": "Draft",
  "action": "Submit for Approval",
  "next_state": "Pending Approval",
  "allowed": "Employee",
  "condition": "doc.amount > 0",
  "allow_self_approval": 0
}
```

| Field | Use |
|-------|-----|
| `state` | Source state |
| `action` | Button label the user clicks |
| `next_state` | Target state |
| `allowed` | Role(s) that can perform this transition. Multiple roles → comma-separated. |
| `condition` | Optional Python expression evaluated with `doc` in scope. Empty = always allowed. |
| `allow_self_approval` | If `0`, blocks the user who created/last-edited the doc from performing this transition. **Always set to 0 on approval transitions.** |

`condition` runs in a restricted context. Keep it simple: `doc.amount > 1000`, `doc.school == "Pune"`. Function calls are limited; complex logic belongs in `validate()`.

## State design rules

1. **Terminal states are idempotent.** "Approved" and "Rejected" should have no outgoing transitions.
2. **Sequential states should be linearly ordered in the `states[]` table.** The order is what the timeline UI shows.
3. **Avoid more than 7 states** — past that, users get lost. Split into two workflows on related DocTypes if needed.
4. **Match `doc_status` to lifecycle.** Submitted (`"1"`) means the doc is locked from edits except `on_update_after_submit`. Cancelled (`"2"`) means archived.
5. **Default state must be reachable on insert.** Frappe sets `workflow_state` to the first state in the table on new docs. The Custom Field `default` should match.

## Programmatic transitions: `db_set` vs `apply_workflow`

There are two ways to move a doc between states programmatically. The team predominantly uses `db_set`.

### `db_set` (team default)

```python
# refund_request.py — pattern from edu_quality
bank_account.save(ignore_permissions=True)
if hasattr(bank_account, "workflow_state"):
    bank_account.db_set("workflow_state", "Approved")
```

```python
# scan_receipts.py — pattern from edu_quality
receipt_doc.workflow_state = "Received"
receipt_doc.save(ignore_permissions=True)
```

What this does:
- Sets the field directly in the DB (or in memory + on next save).
- Skips workflow validation: no `condition` check, no role check, no notification.
- Doesn't fire `update_field` / `update_value` from the state definition.
- Fast, predictable, but bypasses the audit trail the workflow engine provides.

When to use:
- Internal state transitions triggered by other events (an external API came in, a scheduled job ran, a sibling doc was approved).
- Bulk operations where the workflow checks would be redundant.
- Situations where the role check would block the operation but it's intentional (system-driven transition).

### `apply_workflow` (use when you need the checks)

```python
from frappe.model.workflow import apply_workflow

@frappe.whitelist()
def approve_expense(name):
    doc = frappe.get_doc("Expense Claim", name)
    frappe.has_permission("Expense Claim", "write", doc, throw=True)
    apply_workflow(doc, "Approve")  # action name from the transition
    return doc.workflow_state
```

What this does:
- Runs `condition`, role check, `allow_self_approval` check.
- Fires `update_field` / `update_value`.
- Sends notification if `send_email_alert: 1`.
- Returns with the workflow state updated and the doc saved.

When to use:
- User-initiated transitions through a custom UI (a Page or a custom button).
- Anywhere you specifically want the role gating and audit trail.

### The `hasattr` defensive pattern

Wrap any `db_set("workflow_state", ...)` call with `hasattr`:

```python
if hasattr(doc, "workflow_state"):
    doc.db_set("workflow_state", "Approved")
```

Why: the Custom Field may not be applied in every site (multi-site deployments, fresh installs before fixtures run, dev sites that skip customizations). The code should keep working without throwing `AttributeError`.

## DocType permissions vs workflow

The workflow's `allowed` role on a transition is checked **in addition to** the DocType's role permissions. A user must have:
- Read on the DocType
- Write on the DocType (to perform a transition that triggers a save)
- Be in the `allowed` role on the transition

If a transition is silently failing, the most common cause is missing DocType-level Write or Submit perms — not the workflow itself.

## Field-level permissions per state

Per-field permissions per state are not first-class in the Workflow doc. Pattern: gate them in the controller:

```python
class ExpenseClaim(Document):
    def validate(self):
        if self.workflow_state != "Draft":
            for field in ("approval_notes", "approved_amount"):
                if self.has_value_changed(field):
                    if "Expense Approver" not in frappe.get_roles():
                        frappe.throw(_("Only Expense Approver can change {0} after Draft").format(field))
```

Or use `read_only_depends_on` for a UI-only restriction (still pair with a `validate()` check):

```json
{
    "fieldname": "approved_amount",
    "fieldtype": "Currency",
    "read_only_depends_on": "eval:doc.workflow_state != 'Pending Approval'"
}
```

**`read_only_depends_on` is UI-only — never trust it for security.**

## Custom transition handlers

There's no `on_workflow_state_change` lifecycle hook. Check `has_value_changed("workflow_state")` in `validate()` or `before_save()`:

```python
class ExpenseClaim(Document):
    def before_save(self):
        if not self.is_new() and self.has_value_changed("workflow_state"):
            self.handle_state_change(
                old_state=self.get_doc_before_save().workflow_state,
                new_state=self.workflow_state,
            )

    def handle_state_change(self, old_state, new_state):
        if new_state == "Approved":
            self.create_payment_entry()
            self.notify_employee()
```

`get_doc_before_save()` returns the version from the DB before the current save — `None` on insert. Always guard with `is_new()` first.

## Custom workflow DocTypes

When stock Workflow doesn't fit, build a custom DocType for the state machine itself. Precedent in edu_quality:

- **`Funnel Workflow`** — tracks the multi-step student application funnel (`Inquiry → Application → Interview → Offer → Enrollment`). Each row is one applicant's funnel state, with custom fields for stage timestamps and reasons.
- **`fee_workflow` Page** (`edu_quality/page/fee_workflow/`) — Frappe Page (not a DocType) providing a custom UI for fee operations that span multiple DocTypes.

When to reach for this:
- Workflow involves multiple linked documents.
- Transitions need richer UI than the standard Action buttons.
- You need state changes to be queryable / reportable as their own records.
- The "doc" that has the state isn't a single Frappe document.

Pattern:
1. Create a DocType for the workflow state record (e.g. `Funnel Workflow`).
2. Add fields for `current_stage`, `stage_history` (Table), `reference_doctype`, `reference_name`, `actor`, `notes`.
3. Build a Frappe Page (`page/<name>/`) for the UI: a JS file rendering the state machine, a Python file providing whitelisted methods for transitions.
4. Each transition is a whitelisted method: `frappe.has_permission(...)`, validate the transition, update the state, log the change.

## Common gotchas

- **Workflow doesn't fire on `db_set`** — by design (see "Programmatic transitions" above). When the team needs the engine's checks/notifications, they call `apply_workflow`. When they don't, they `db_set` deliberately.
- **Workflow alongside `is_submittable: 1`** — if the DocType has `is_submittable`, the workflow's `doc_status` field must agree with `docstatus`. Inconsistent setups lead to docs that are "Approved" in workflow but `docstatus: 0` in the DB.
- **Stuck workflow_state after error** — if a `before_save` handler throws after the state has been updated but before the doc is saved, the in-memory state and the DB diverge. Always do side effects in `on_submit` / `on_update`, never inline in transition handlers.
- **`condition` failures** — if the Python expression throws (e.g. `doc.amount > 0` when `amount` is `None`), the action is hidden from the user with no error message. Test with NULL fields.
- **Default `workflow_state` on existing rows** — adding a workflow to a DocType with existing rows leaves their `workflow_state` field NULL. Add a `before_migrate` patch to backfill (the Custom Field's `default` only applies to new rows).
- **`apply_workflow` reload pitfall** — after `apply_workflow`, the doc in your variable is updated in memory, but if you reload it elsewhere (e.g. `frappe.get_doc(...)` later in the same request) you may get a stale copy if the cache hasn't been invalidated. `frappe.clear_cache(doctype="...")` if it matters.
- **Funnel Workflow patches** — when removing/renaming Funnel Workflow rows, the team's pattern is a delete patch (see `patches/funnel_workflow.py`) rather than a Frappe migration. Patches must be idempotent.

## Migration: adding a workflow to an existing DocType

1. Add the `workflow_state` Custom Field via the customizations sub-app (see "Adding workflow_state via Custom Field" above).
2. Run `bench migrate` to apply the Custom Field.
3. Backfill existing rows via patch:

```python
# my_app/patches/v1_0/backfill_expense_workflow_state.py
import frappe


def execute():
    frappe.db.sql("""
        UPDATE `tabExpense Claim`
        SET workflow_state = CASE
            WHEN docstatus = 0 THEN 'Draft'
            WHEN docstatus = 1 THEN 'Approved'
            WHEN docstatus = 2 THEN 'Rejected'
            ELSE 'Draft'
        END
        WHERE workflow_state IS NULL
    """)
    frappe.db.commit()
```

Add to `patches.txt`:
```
my_app.patches.v1_0.backfill_expense_workflow_state
```

4. Create the Workflow via fixtures or desk. Set `is_active: 1` only after backfill completes.

## See also

- `references/doctype-json.md` (in `frappe-review` skill) — schema-level checks for DocType fields including `workflow_state`
- `server-scripts` skill — controller hooks (`validate`, `before_save`) used in transition handlers
- `frappe-debug` skill — bench error log monitor catches transition handler exceptions
- `frappe-erpnext` agent — for Custom Field strategy across the customizations sub-app
