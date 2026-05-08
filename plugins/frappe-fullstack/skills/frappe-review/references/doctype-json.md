# DocType JSON — Schema Review

DocType JSON files live at `{app}/{module}/doctype/{doctype}/{doctype}.json`. Review for structural correctness, naming conventions, permission hygiene, and schema-change safety.

---

## Field design

### 🟠 Major
- **`Data` field used for predefined options** — fixed value sets should be `Select` or `Link`, not `Data`. Data fields invite typos and inconsistency.
- **Missing `mandatory` flag** on fields that must always be filled (e.g., `student_name` on a Student DocType). If `validate()` enforces it in code, the JSON should too — defense in depth.
- **Wrong field type for size of value:** use `Data` for short single-line strings (<140 chars), `Small Text` for multi-line (<500 chars), `Text` for longer content, `Long Text` for very large.
- **`Currency` / `Float` fields without `precision`** — leads to rounding errors.
- **`Link` field pointing to a non-existent or suspiciously-named DocType.**
- **Missing `in_list_view: 1`** on important fields — if a child table has 10 fields but none are flagged, the list view is useless.
- **`link` field with no `options`** (target DocType) — schema is broken.

### 🟡 Minor
- Field labels not Sentence Case — Frappe convention is "Student Name", not "student_name" or "STUDENT NAME".
- `fieldname` not snake_case — all fieldnames must be lowercase snake_case.
- `fieldname` matches a Python builtin (`type`, `class`, `from`).
- `Section Break` / `Column Break` without a label where one would aid readability.
- `hidden: 1` field that's also `mandatory: 1` — contradictory unless set via code.
- Overly long `fieldname` (>40 chars).
- Missing `description` on a field where the label alone is ambiguous.

### 💡 Suggestions
- Use `Tab Break` to organize forms with many fields (v15 feature).
- Always-computed fields should have `read_only: 1` to prevent manual editing.
- `Attach` fields can specify `options` for allowed file types.

---

## Naming & autoname

### 🟠 Major
- **Missing `autoname` pattern** — DocType falls back to a random hash, rarely desired for master data. Use `naming_series`, `field:{fieldname}`, `format_string`, or `Prompt`.
- **`autoname: Prompt` on a transactional DocType** — users shouldn't manually name transactions.
- **`autoname: field:` pointing to a non-unique field** — guaranteed duplicate-name errors.

### 🟡 Minor
- Naming series pattern doesn't follow team convention (e.g., `STU-.YYYY.-` for Student).
- Naming series prefix too generic (e.g., `REC-`) — collisions across modules.

---

## Permissions

### 🔴 Critical
- **`permissions: []`** — DocType is unusable for non-admins; flag every time.
- **`allow_guest_access: 1`** without strong justification — public access to a DocType.
- **Write / Delete permissions granted to roles that should be read-only** for this DocType.

### 🟠 Major
- Overly permissive role — e.g., "All" with write access to a sensitive DocType.
- Missing role for a workflow actor — if there's a workflow, the approver role must have the right permissions.
- `user_permission_doctypes` misconfigured, breaking multi-tenant isolation.

### 🟡 Minor
- Missing `report` / `export` for roles that likely need them.
- Inconsistent permission levels across related DocTypes.

---

## Workflow & submission

### 🟠 Major
- **`is_submittable: 1` without `on_submit` / `on_cancel` handlers** — submittable DocTypes usually need side effects (ledger entries, notifications). If neither exists, question why it's submittable.
- Workflow states reference roles that don't exist in the permission model.
- Missing `default` workflow state for new documents.
- Submittable DocType permission row missing `submit: 1` / `cancel: 1` for the actor role.

### 🟡 Minor
- `is_submittable` on a DocType that doesn't represent a transaction (overengineering).
- Workflow with too many states (>7) — consider simplifying.

---

## Child tables

### 🟠 Major
- **Child DocType without `istable: 1`** — appears in the sidebar as a standalone DocType.
- **Parent DocType not listing the child table field** — orphaned child table definition.
- Child table fields missing `in_list_view: 1` — at least 2-3 fields should be visible.
- Child table without any `reqd` fields when every row needs certain values.

### 🟡 Minor
- Child table with too many fields (>15) — consider whether some belong on the parent.
- Missing `idx` handling notes if row order matters.

---

## Schema changes in PRs

When a diff modifies a DocType JSON, pay special attention to:

### 🔴 Critical
- **Removing a field that may contain production data** without a patch.
- **Changing field type** (e.g., `Data` → `Int`) without a data migration patch.
- **Renaming a `fieldname`** — does not auto-migrate; needs a `frappe.rename_field` patch in `patches.txt`.

### 🟠 Major
- **Adding a `mandatory` field** without a default value or backfill patch — existing rows fail to load / save.
- **Changing `autoname`** on a DocType with existing data.
- **Modifying permissions** that could lock out existing users.
- **No corresponding patch file** when a schema change requires data migration. Check `patches.txt` for a new entry.

### 🟡 Minor
- Field-order changes that confuse users familiar with the current layout.
- Adding fields without updating print formats that display the DocType.

---

## JSON hygiene

### 🟡 Minor
- **`modified` / `modified_by` changes** in the JSON diff — auto-generated, create noisy diffs. Strip before commit. Flag as noise but don't block.
- **`creation` timestamp changes** on existing DocTypes — suspicious, likely an accidental re-export.
- Inconsistent `sort_field` / `sort_order` — should match how users expect to see records.
- `track_changes: 0` on DocTypes where audit trail matters (financial, permissions, master data).
- `allow_rename: 0` on master data where admins may need to rename.
