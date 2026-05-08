# Changelog

This plugin omits `version` from `plugin.json`, so Claude Code uses the git commit SHA as the version. Each commit on `main` ships to users on `/plugin update`. Group notable changes here by SHA range or PR for release notes.

## Unreleased — post cc2c934

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
