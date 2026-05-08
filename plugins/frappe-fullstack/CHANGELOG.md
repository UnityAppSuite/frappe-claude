# Changelog

This plugin omits `version` from `plugin.json`, so Claude Code uses the git commit SHA as the version. Each commit on `main` ships to users on `/plugin update`. Group notable changes here by SHA range or PR for release notes.

## Unreleased — post 95eba12

- Added four model-invoked reference skills covering surfaces the plugin previously didn't, **aligned to the team's edu_quality conventions**:
  - `workflow-patterns` — Frappe Workflow design + edu_quality deviations: `workflow_state` added via Custom Field in `sc_customizations` (not source DocType edits), pragmatic use of `db_set` over `apply_workflow` for programmatic transitions, `hasattr(doc, "workflow_state")` defensive pattern, when to build a custom workflow DocType + Page (Funnel Workflow / fee_workflow precedent).
  - `print-format` — **Self-contained format convention** (no `{{ letter_head }}` / `{{ footer }}` injection — explicitly contrary to upstream Frappe convention), `pdf_generator: "wkhtmltopdf"` pinned, `formatdate(date, "dd-MM-yyyy")` standard, `Rs.` instead of `₹` (font issue dodge), `15.0` margins all sides, two-mode distinction (`custom_format: 1` raw HTML vs `custom_format: 0` Builder `format_data`), inline `frappe.db.get_value` Jinja idiom, full Fee Receipt example matching the Fees module style.
  - `testing-patterns` — `FrappeTestCase`, factory pattern, fixture isolation, mocking `frappe.sendmail` / external HTTP / `publish_realtime`, permission tests, `change_settings`, anti-patterns, full controller test example.
  - `scheduler-and-jobs` — production-grade companion to `server-scripts`; queue selection, `enqueue_after_commit`, idempotency, distributed locks (cache + SETNX), retries with backoff, monitoring stuck jobs, debugging worker hangs, chunked long-running jobs. Real-world `scheduler_events.cron` block from `edu_quality/hooks.py` and the two-step scheduler-entry → `enqueue(queue="long")` pattern from `assessment_pdf_scheduler.py`.
- Added `/frappe-perf` command (read-only) — runs `bench doctor`, `show-pending-jobs`, MariaDB slow query log inspection, N+1 search in the working-tree diff, and a perf-related error scan of `web.error.log`/`worker.error.log`. Each step is independent; no destructive operations.
- Added second monitor entry `bench-access-log` to `monitors/monitors.json` — tails `web.log` filtered through `grep -E '(WARNING|ERROR| 4xx | 5xx |slow)'` so the debugger sees problem requests live without drowning in 200 OKs. Triggered `on-skill-invoke:frappe-debug` alongside the existing `bench-error-log` monitor.

## post 3c2bd51 — code review skill

- Added `frappe-reviewer` agent (read-only) that performs Frappe-aware code review focused on controller hook misuse, whitelisted-API auth/permission/SQL-injection risks, DocType JSON correctness, frontend patterns (React/Vue/RN/classic Frappe client scripts), `hooks.py` performance, and ERPNext customization risks.
- Added `frappe-review` skill that auto-invokes on "review my changes", "review this PR", or a `github.com/*/pull/*` URL. Two modes:
  - **Local diff (default)**: `git diff HEAD`; also accepts last commit / branch / file targets.
  - **GitHub PR**: uses `gh pr view` / `gh pr diff` with the user's existing `gh auth login` or `GH_TOKEN`. Posting the review back to GitHub is opt-in only — never automatic.
- Adopted progressive-disclosure pattern: rules split into `skills/frappe-review/references/{security,frappe-python,doctype-json,frontend}.md`. The agent loads only the references that match the file types in the diff, so context stays small for small reviews.
- Switched output to the 🔴 Critical / 🟠 Major / 🟡 Minor / 💡 Suggestion severity scheme with a verdict (✅ Approve / 🔄 Request Changes / 💬 Needs Discussion), a "What's done well" section, and a file-by-file summary table. Includes Universal Checks (hardcode detection, dead code, naming/readability, error handling, DRY) and edge-case rules (large diffs, migrations, tests, generated files, merge commits).

## post cc2c934 — alignment with current plugin spec (3c2bd51)

- Removed `"version": "1.0.0"` pin from `plugin.json` so updates propagate on every commit (per https://code.claude.com/docs/en/plugins-reference#version-management).
- Added `$schema`, `repository`, and `userConfig` (`bench_path`, `default_site`, `python_path`) to `plugin.json`.
- Fixed missing YAML frontmatter on `agents/frappe-custom-frontend.md` so it loads as an agent.
- Replaced obsolete `Task` tool references with `Agent`, and `TodoWrite` with `TaskCreate` / `TaskUpdate`, in commands and agents.
- Removed thin wrapper commands `/frappe-backend`, `/frappe-frontend`, `/frappe-debug`, `/frappe-erpnext`, `/react-spa`, `/react-native` — Claude routes to the corresponding agents automatically by description.
- Added `hooks/hooks.json` with a `SessionStart` hook that injects bench/site context, and a `PostToolUse` hook on `Write|Edit` that runs `ruff format` on Python files inside the bench and prints a `bench migrate` reminder when DocType JSON or `hooks.py` changes.
- Added `monitors/monitors.json` with a `bench-error-log` monitor that tails `web.error.log` and `worker.error.log` whenever the new `frappe-debug` skill is invoked.
- Added new `frappe-debug` skill that triggers the monitor and structures debugging triage before handing off to the `frappe-debugger` agent.
- Added `category` and `tags` to the `frappe-fullstack` entry in `marketplace.json`.

## cc2c934 — Merge react-spa and react-native frontend extensions

- Added `react-spa-frontend` and `react-native-frontend` agents.
- Added `react-spa-patterns` and `react-native-patterns` skills.

## 9cd04f8 — Merge frappe-custom-frontend agent

- Added `frappe-custom-frontend` agent (Doppio-based React/Vue SPAs embedded in Frappe).

## 8e13f8b — frappe-planner plan-mode support

- `frappe-planner` agent and `/frappe-plan` command now use Claude Code's plan mode (`EnterPlanMode` / `ExitPlanMode`).
