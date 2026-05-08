---
description: Run Frappe performance diagnostics — bench doctor, pending/stuck jobs, MariaDB slow query log, N+1 search in recent diff, recent perf-related errors. Read-only; no execution of destructive commands.
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "[--diff] [--queries] [--jobs] [--errors] [--all]"
---

# Frappe Performance Diagnostics

Surface the most common Frappe/ERPNext perf problems in a single pass: stuck background jobs, slow queries, N+1 patterns in recent code changes, and perf-related errors in the bench log.

Read-only. Does not enable / disable settings, restart services, or modify the database. Each step is independent — if one fails, the others continue.

## Arguments

Parse `$ARGUMENTS`:

| Flag | Step |
|------|------|
| `--jobs` | Step 2 only (pending / stuck jobs) |
| `--queries` | Step 3 only (slow query log) |
| `--diff` | Step 4 only (N+1 search in diff) |
| `--errors` | Step 5 only (recent error log scan) |
| `--all` *(default if no flag given)* | Steps 1–5 in order |

## Prerequisites

The `frappe-fullstack` plugin's userConfig must be populated:
- `${user_config.bench_path}` — absolute path to `frappe-bench/`
- `${user_config.default_site}` — site name to inspect

If either is missing, ask the user once and stop. Do not guess.

## Steps

### Step 1 — bench doctor (always runs in `--all` mode)

`bench doctor` is Frappe's built-in health check: scheduler status, pending RQ jobs, last-run timestamps. Surface the output verbatim under a heading.

```bash
cd "${user_config.bench_path}" && bench --site "${user_config.default_site}" doctor
```

If `bench` is missing or the site is invalid, capture the error and continue.

### Step 2 — pending / stuck jobs

```bash
cd "${user_config.bench_path}" && bench --site "${user_config.default_site}" show-pending-jobs
```

Parse the output. For each pending job, surface:
- Job ID
- Method (e.g. `my_app.tasks.process_invoice`)
- Queue (`short` / `default` / `long`)
- Age — flag any job older than the queue's default timeout (60s short / 300s default / 1500s long) as **likely stuck**

If `bench show-pending-jobs` is unavailable on this Frappe version, fall back to:
```bash
cd "${user_config.bench_path}" && bench --site "${user_config.default_site}" execute "frappe.utils.background_jobs.get_jobs"
```

### Step 3 — MariaDB slow query log

Check whether the slow query log is enabled and, if so, surface the last 50 lines.

```bash
cd "${user_config.bench_path}" && bench --site "${user_config.default_site}" mariadb \
  -e "SHOW VARIABLES WHERE Variable_name IN ('slow_query_log','slow_query_log_file','long_query_time');"
```

Three cases:

**Slow log ON** — find the file path from the `SHOW VARIABLES` output and tail it:
```bash
sudo tail -50 "<slow_query_log_file>"
```
Surface the queries with their query times. Group identical (modulo literals) queries together. If a query appears multiple times, that's a hot spot.

**Slow log OFF** — print the one-liner to enable it temporarily, but DO NOT run it:
```sql
-- Run this in MariaDB to enable slow log for diagnosis (revert after):
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 0.5;     -- 500ms
SET GLOBAL slow_query_log_file = '/tmp/frappe_slow.log';
-- After diagnosis:
SET GLOBAL slow_query_log = 'OFF';
```

**Cannot connect** — surface the error and skip this step.

### Step 4 — N+1 candidates in recent diff

Look for the classic Frappe N+1 anti-pattern: `frappe.get_doc` / `frappe.get_all` / `frappe.db.sql` / `frappe.db.get_value` inside a `for` or `while` loop in changed Python files.

```bash
# Files changed in working tree
cd "${user_config.bench_path}" && git diff HEAD --name-only --diff-filter=AM | grep '\.py$' > /tmp/_perf_changed_py
```

For each changed Python file, scan with grep:

```bash
while IFS= read -r f; do
  awk '
    /^[[:space:]]*(for|while)\b.*:/ { in_loop=NR; loop_line=$0 }
    in_loop && NR > in_loop && NR <= in_loop + 25 {
      if (/frappe\.(get_doc|get_all|get_list|db\.sql|db\.get_value|db\.get_all|db\.count|db\.exists)/) {
        printf "%s:%d: in loop opened at line %d -- %s\n", FILENAME, NR, in_loop, $0
      }
    }
    /^[^[:space:]]/ && in_loop && NR > in_loop + 1 { in_loop=0 }
  ' "${user_config.bench_path}/$f"
done < /tmp/_perf_changed_py
```

For each match, report:
- `path/to/file.py:LINE` — which DB call and which loop it's inside
- A one-line suggestion: "fetch in batch with `frappe.get_all(... filters={'name': ['in', list]} ...)` and build a dict"

**Note false positives:** the heuristic also flags legitimate per-loop calls (e.g. inside a callback or when the call is bounded). Mark these as candidates, not findings.

### Step 5 — recent perf-related errors

```bash
tail -200 "${user_config.bench_path}/sites/${user_config.default_site}/logs/web.error.log" 2>/dev/null \
  | grep -iE '(timeout|memorerror|out of memory|killed|too many connections|deadlock|gunicorn worker|worker timeout|429|502|503|504)' \
  | tail -20
```

Surface up to 20 most recent matches with timestamps. Group by error type if patterns are obvious.

Also scan the worker log for OOM kills:

```bash
tail -200 "${user_config.bench_path}/sites/${user_config.default_site}/logs/worker.error.log" 2>/dev/null \
  | grep -iE '(killed|memory|timeout|stuck)' \
  | tail -10
```

## Output format

Surface a structured Markdown report. Each step gets its own section. Lead with a one-line summary at the top.

```markdown
# Frappe Performance Diagnostics — <site>

**Summary:** {one line — e.g. "3 stuck jobs, 5 slow queries, 2 N+1 candidates in diff"}

## bench doctor
<verbatim output, fenced>

## Pending / stuck jobs
- `job-id-abc` — `my_app.tasks.foo` on `short` queue, **180s old (likely stuck — short timeout is 60s)**
- ...

## Slow queries (last 50 from /var/log/mysql/slow.log)
- 12 occurrences of `SELECT ... FROM tabSales Invoice WHERE customer = ?` averaging 1.8s
- 1 occurrence of `SELECT ... FROM tabBin JOIN ...` taking 12s

## N+1 candidates in diff
- `apps/my_app/my_app/api.py:42` — `frappe.get_doc("Customer", row.customer)` inside `for row in invoices:` (line 38). Suggest: prefetch with `customers = {c.name: c for c in frappe.get_all("Customer", filters={"name": ["in", customer_names]}, fields=["..."])}`.

## Recent perf-related errors (last 20)
- 5x worker timeout in `process_bulk_import` over the last hour
- 2x deadlock in tabSales Invoice
```

## Exit behavior

- Always exits 0, even if individual steps fail.
- If userConfig is missing, exits early with a one-line message and no other output.
- Never mutates state. The "enable slow query log" SQL is printed for the user to run manually if they want.

## See also

- `scheduler-and-jobs` skill — patterns for fixing the stuck/slow jobs this command surfaces
- `references/frappe-python.md` (in `frappe-review` skill) — review-time N+1 checks (this command finds them in working-tree diffs)
- `bench-commands` skill — manual usage of `bench doctor`, `show-pending-jobs`, `mariadb`
