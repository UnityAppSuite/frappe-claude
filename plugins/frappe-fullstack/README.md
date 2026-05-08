# Frappe Full Stack Plugin for Claude Code

A comprehensive Claude Code plugin for Frappe Framework and ERPNext full-stack development. Bundles 11 specialized agents, 9 user commands, 13 skills, plus hooks, two background log monitors (error log + filtered access log), and one-time userConfig prompts for `bench_path` and `default_site`.

## Features

- **DocType development** — scaffold complete DocTypes with JSON, controllers, and client scripts
- **Specialized agents** — backend, classic frontend, React SPA, React Native, custom (Doppio) frontend, ERPNext, debugging, code review, planning, DocType architecture, GitHub workflow
- **Bench integration** — safe execution of bench CLI commands plus a `bench-commands` reference skill
- **Skills** — auto-invoked knowledge for Frappe patterns, APIs, and the new `frappe-debug` triage flow
- **Hooks** — auto-format Python on save, migrate-reminders on DocType / hooks.py edits, bench context injection at session start
- **Monitor** — tails `web.error.log` and `worker.error.log` whenever the `frappe-debug` skill is invoked

## Installation

### From the marketplace

```bash
git clone https://github.com/UnityAppSuite/frappe-claude.git
/plugin marketplace add ./frappe-claude
/plugin install frappe-fullstack@frappe-claude
```

On first install you'll be prompted for:

| Field | Type | Required | Use |
|-------|------|----------|-----|
| `bench_path` | directory | yes | Absolute path to your `frappe-bench/` (the dir containing `apps/`, `sites/`, `env/`) |
| `default_site` | string | yes | Default site name (e.g. `dev.localhost`); used by hooks and the error-log monitor |
| `python_path` | file | no | Path to bench's Python interpreter; leave blank to detect |

These values are reused by the hooks and the monitor; they're substituted as `${user_config.bench_path}` etc. and exported as `CLAUDE_PLUGIN_OPTION_BENCH_PATH` to subprocesses.

### For local development

```bash
claude --plugin-dir ./plugins/frappe-fullstack
```

## Components

### Slash commands (9)

| Command | Description |
|---------|-------------|
| `/frappe-fullstack` | Multi-agent orchestration — coordinates DocType, backend, frontend, ERPNext agents in parallel |
| `/frappe-plan` | Strategic plan-mode entry; saves a markdown plan |
| `/frappe-doctype-create` | Scaffold a new DocType (JSON + controller + client script + test) |
| `/frappe-doctype-field` | Add / modify / remove fields on an existing DocType |
| `/frappe-app` | `bench new-app` workflow with module setup |
| `/frappe-bench` | Safe wrapper for `bench` CLI commands |
| `/frappe-test` | Run Frappe tests (per-app, per-DocType, per-module, with coverage) |
| `/frappe-perf` | Read-only performance diagnostics — `bench doctor`, pending/stuck jobs, slow query log, N+1 search in working-tree diff, recent perf-related errors |
| `/frappe-github` | Git/GitHub workflows — branch, commit, PR, with team conventions |

> **Single-agent commands like `/frappe-backend`, `/react-spa`, `/frappe-debug` were removed.** Their agents (below) are still here and Claude routes to them automatically by description, or you can invoke them explicitly via `/agents`.

### Agents (11)

| Agent | Description |
|-------|-------------|
| `doctype-architect` | Design DocTypes and data models |
| `frappe-backend` | Server-side Python (controllers, APIs, background jobs) |
| `frappe-frontend` | Client-side JavaScript (form scripts, dialogs, list views) |
| `frappe-custom-frontend` | Doppio-based React/Vue SPAs embedded in Frappe apps |
| `react-spa-frontend` | React 18 + Vite + shadcn/ui or Refine + Mantine SPAs |
| `react-native-frontend` | Expo / React Native mobile apps backed by Frappe |
| `erpnext-customizer` | ERPNext customization patterns |
| `frappe-debugger` | Deep debugging and traceback analysis |
| `frappe-reviewer` | Frappe-aware code review (read-only) — security, permissions, hook misuse, DocType JSON correctness, frontend (React/Vue/RN) patterns; emits 🔴/🟠/🟡/💡 findings with verdict |
| `frappe-planner` | Strategic planning with plan-mode support |
| `github-workflow` | Branch / commit / PR conventions |

### Skills (13)

| Skill | Triggers when |
|-------|---------------|
| `doctype-patterns` | Creating or modifying DocTypes |
| `frappe-api` | Working with `frappe.get_doc`, `frappe.db`, `frappe.call`, REST endpoints |
| `bench-commands` | Running `bench` CLI operations |
| `client-scripts` | Form events, dialogs, list view customization |
| `server-scripts` | Controllers, APIs, background jobs (basic syntax) |
| `react-spa-patterns` | React SPA work backed by Frappe |
| `react-native-patterns` | React Native / Expo work backed by Frappe |
| `frappe-debug` | Triaging an error or unexpected behavior — also starts the bench log monitors |
| `frappe-review` | "Review my changes" / pre-commit review or `github.com/*/pull/*` URL — gathers diff (local via `git` or remote via `gh pr diff`), runs `ruff`/`eslint`, loads domain reference rules, hands off to `frappe-reviewer` |
| `workflow-patterns` | Designing a Frappe Workflow — multi-state document lifecycles, role-based transitions, state-scoped field permissions, transition handlers |
| `print-format` | Designing or troubleshooting Print Formats / PDF output — Jinja templates, page breaks, multi-currency, letter heads, wkhtmltopdf vs Chromium |
| `testing-patterns` | Writing `FrappeTestCase` tests — factories, fixture isolation, mocking `frappe.sendmail` / external HTTP, permission tests, anti-patterns |
| `scheduler-and-jobs` | Production-grade background jobs — queue selection, idempotency, retries, distributed locks, monitoring stuck jobs, chunked long-running work (complements `server-scripts`) |

### Hooks (`hooks/hooks.json`)

| Event | Matcher | Behavior |
|-------|---------|----------|
| `SessionStart` | — | `scripts/session-context.sh` echoes detected `bench_path`, `default_site`, Frappe version, and installed apps into the session |
| `PostToolUse` | `Write\|Edit` | `scripts/post-edit.sh` runs `ruff format` + import sort on Python files inside `bench/apps/`, and prints a `bench migrate` reminder when DocType JSON or `hooks.py` changes |

The post-edit hook silently no-ops when `ruff` or `jq` aren't installed, and always exits 0 so it never blocks Claude.

### Monitors (`monitors/monitors.json`)

Two background monitors, both triggered `on-skill-invoke:frappe-debug` so they only run when actively debugging:

| Monitor | What it watches |
|---------|-----------------|
| `bench-error-log` | `tail -F sites/<default_site>/logs/web.error.log` + `sites/<default_site>/logs/worker.error.log` — every error appears as a Claude notification |
| `bench-access-log` | `tail -F sites/<default_site>/logs/web.log` filtered through `grep -E '(WARNING\|ERROR\| 4xx \| 5xx \|slow)'` — surfaces problem requests without drowning in 200 OKs |

The grep filter on the access log keeps signal-to-noise high — successful responses don't reach Claude, only warnings, errors, 4xx/5xx status codes, and lines containing "slow".

## Usage examples

### Multi-agent feature build
```
/frappe-fullstack Build a customer feedback system with ratings, categories, follow-up actions, and email notifications
```

### Plan first, then implement
```
/frappe-plan Inventory reorder system with automatic purchase order generation
```
The plan is saved as markdown so you can iterate on it before executing.

### Direct agent (auto-routed by description)
Just describe the work; Claude picks the right agent:
```
Add validation to ensure order total doesn't exceed customer credit limit
```
→ routes to `frappe-backend`.

### Debug an error
```
/frappe-fullstack:frappe-debug Getting "Permission denied" when submitting Sales Invoice as Sales User
```
The skill starts the error-log monitor, walks through standard checks, and hands off to `frappe-debugger` for the deep work.

### Review changes before committing
```
review my changes
```
or explicitly:
```
/frappe-fullstack:frappe-review
```
Defaults to `git diff HEAD` (working tree). The skill collects the diff, runs `ruff`/`eslint`, then hands off to `frappe-reviewer` which loads only the domain references it needs (`security.md` always, plus `frappe-python.md` / `doctype-json.md` / `frontend.md` per file type) and emits a structured report:

```
## 🔍 Frappe Review — <scope>
**Verdict:** ✅ Approve | 🔄 Request Changes | 💬 Needs Discussion
**Issues:** 🔴 n  🟠 n  🟡 n  💡 n
### 🌟 What's done well   ### 🔴 Critical   ### 🟠 Major   ### 🟡 Minor   ### 💡 Suggestions
### File-by-file summary  | path | status | issues |
```

### Review a GitHub PR
```
review https://github.com/owner/repo/pull/123
```
Switches to PR mode: uses `gh pr view` / `gh pr diff` (your existing `gh auth login` or `GH_TOKEN`). The review surfaces in chat. **Posting the review back to the PR requires you to explicitly say "post the review"** — never automatic.

### Scaffolding
```
/frappe-doctype-create "Project Task" my_module
/frappe-doctype-field "Sales Order" add custom_priority Select "Low\nMedium\nHigh"
/frappe-app my_custom_app --title "My Custom App" --module Core
```

### Bench utilities
```
/frappe-bench migrate --site mysite.local
/frappe-bench build --app my_app
/frappe-test my_app --coverage
/frappe-test --doctype "Sales Invoice"
```

### Performance diagnostics
```
/frappe-perf            # all checks: bench doctor, stuck jobs, slow queries, N+1 in diff, recent perf errors
/frappe-perf --jobs     # only stuck-job check
/frappe-perf --diff     # only N+1 candidates in working-tree diff
```
Read-only; never modifies settings or restarts services. The "enable slow query log" SQL is printed for you to run manually if you want to capture a slow log.

### Git workflow
```
/frappe-github create branch    # prompts for type / task-id / description
/frappe-github commit           # no co-author footer
/frappe-github create pr        # pushes + opens PR
```

## Directory structure

```
frappe-fullstack/
├── .claude-plugin/
│   └── plugin.json              # Manifest — no `version` (uses git SHA)
├── agents/                      # 11 .md files, all with frontmatter
├── commands/                    # 9 .md files (user-typed entry points)
├── skills/                      # 13 SKILL.md folders (model-invoked)
│   ├── frappe-review/
│   │   ├── SKILL.md
│   │   └── references/          # Progressive-disclosure rule files
│   │       ├── security.md      # Always loaded
│   │       ├── frappe-python.md # Loaded for *.py / hooks.py / Jinja
│   │       ├── doctype-json.md  # Loaded for doctype/*.json
│   │       └── frontend.md      # Loaded for *.{js,ts,tsx,vue}
│   ├── workflow-patterns/SKILL.md
│   ├── print-format/SKILL.md
│   ├── testing-patterns/SKILL.md
│   └── scheduler-and-jobs/SKILL.md
├── hooks/
│   └── hooks.json
├── monitors/
│   └── monitors.json
├── scripts/
│   ├── session-context.sh       # SessionStart hook
│   └── post-edit.sh             # PostToolUse hook (Write|Edit)
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Agent capabilities matrix

| Agent | Python | JavaScript | DocType | ERPNext | React | Debug | Planning |
|-------|--------|------------|---------|---------|-------|-------|----------|
| doctype-architect | - | - | ✓✓✓ | ✓ | - | - | - |
| frappe-backend | ✓✓✓ | - | ✓ | ✓ | - | ✓ | - |
| frappe-frontend | - | ✓✓✓ | ✓ | ✓ | - | - | - |
| frappe-custom-frontend | - | ✓✓ | - | - | ✓✓ (Doppio) | - | - |
| react-spa-frontend | - | ✓✓ | - | - | ✓✓✓ | - | - |
| react-native-frontend | - | ✓✓ | - | - | ✓✓✓ (Expo) | - | - |
| erpnext-customizer | ✓✓ | ✓ | ✓ | ✓✓✓ | - | - | - |
| frappe-debugger | ✓ | ✓ | ✓ | ✓ | - | ✓✓✓ | - |
| frappe-reviewer | ✓✓ | ✓✓ | ✓✓ | ✓✓ | ✓ | ✓ | - |
| frappe-planner | ✓ | ✓ | ✓✓ | ✓✓ | ✓ | - | ✓✓✓ |
| github-workflow | - | - | - | - | - | - | ✓ |

## Frappe version compatibility

- Frappe Framework v14+
- ERPNext v14+

Most patterns are backward compatible with v13.

## Versioning

This plugin omits `version` in `plugin.json`. Per the [version-management spec](https://code.claude.com/docs/en/plugins-reference#version-management), Claude Code falls back to the git commit SHA, so every commit on `main` ships to users on `/plugin update`. If you fork and want stable semver releases instead, add `"version": "x.y.z"` and bump it on every push.

## Troubleshooting

```bash
# Validate manifests, frontmatter, and hooks.json
claude plugin validate .

# Inspect plugin loading and component registration
claude --debug

# Reload after editing files (no restart needed)
/reload-plugins
```

If hooks don't fire: ensure `scripts/*.sh` are executable (`chmod +x`) and that `jq` is on `$PATH`. If the monitor doesn't start: confirm `default_site` matches a real site under `bench_path/sites/`.

## Best practices

### DocType development
1. Use singular names: "Customer" not "Customers"
2. Follow Title Case: "Sales Invoice"
3. Use snake_case for fieldnames: `customer_name`

### Code organization
1. Keep controllers focused on business logic
2. Use separate utility files for shared functions
3. Write tests alongside features

### ERPNext customization
1. Never modify core ERPNext files
2. Use hooks and custom fields
3. Export customizations as fixtures (or apply via `after_migrate`)

## Contributing

1. Fork the repository
2. Create a feature branch (`feature/<task-id>-<desc>`)
3. Add/modify components
4. Run `claude plugin validate .`
5. Test with `claude --plugin-dir ./plugins/frappe-fullstack`
6. Submit a PR

## License

MIT — see `LICENSE`.

## Resources

- [Frappe Framework Documentation](https://frappeframework.com/docs)
- [ERPNext Documentation](https://docs.erpnext.com)
- [Claude Code Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Plugin Reference](https://code.claude.com/docs/en/plugins-reference)
