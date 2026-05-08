---
description: Investigate a Frappe/ERPNext error or unexpected behavior. Use when the user reports an exception, a 500 response, a permission error, a slow query, a stuck background job, or an unexpected DocType state.
---

# Frappe Debug

Use this skill when something is broken in a Frappe or ERPNext site and the next step is diagnosis, not implementation. Invoking it also starts the `bench-error-log` background monitor (defined in this plugin's `monitors/monitors.json`), so new tracebacks from `web.error.log` and `worker.error.log` arrive as notifications during the session.

## Standard checks

Work through these in order; stop as soon as the symptom is reproduced and the root cause is clear.

1. **Frame the failure**
   - Exact error message or HTTP status, with the user's reproduction steps.
   - Which DocType, API endpoint, scheduled job, or page is involved.
   - First-seen-on: was this working previously? what changed (recent migrate, app install, hooks.py edit)?

2. **Read the live logs**
   The monitor is already tailing `web.error.log` and `worker.error.log` for the configured site. Cross-reference the timestamp of the user's reproduction with the most recent traceback. If the monitor has not surfaced anything, also check:
   - `${user_config.bench_path}/sites/${user_config.default_site}/logs/scheduler.log`
   - `${user_config.bench_path}/sites/${user_config.default_site}/logs/web.log`
   - `${user_config.bench_path}/logs/bench.log`

3. **Reproduce in `bench console`**
   ```bash
   bench --site ${user_config.default_site} console
   ```
   Import the relevant DocType controller, instantiate or fetch a document, and call the failing method directly. This narrows the failure surface from "request pipeline" to "Python logic".

4. **Check permissions**
   If the error is a `PermissionError` or unexpected empty result:
   - `frappe.permissions.has_permission(doctype, ptype, doc=name, user=user)`
   - Inspect the DocType's permission rules, role profile, and User Permissions on the affected user.

5. **Inspect database state**
   ```bash
   bench --site ${user_config.default_site} mariadb
   ```
   Confirm the row exists, owner is correct, no orphaned child rows, no stuck workflow_state. Compare `tabSingles` for Single doctypes.

6. **Check recent migrations**
   ```bash
   bench --site ${user_config.default_site} list-apps
   bench --site ${user_config.default_site} migrate --dry-run
   ```
   A pending or partial migration is a frequent cause of "field doesn't exist" / "table doesn't exist".

## Hand off to the debugger agent

Once the failure is framed and basic logs are in hand, route the deep investigation to the specialist:

> Use the `frappe-fullstack:frappe-debugger` agent with all of the above as context. Pass it the error message, the reproduction steps, the relevant traceback, and any log lines the monitor has surfaced.

Do not attempt fixes from this skill. Diagnose first; the appropriate agent (`frappe-debugger` for analysis, `frappe-backend` / `erpnext-customizer` / `frappe-frontend` for the actual fix) handles the change.
