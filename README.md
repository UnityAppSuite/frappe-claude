# Frappe Claude — Plugin Marketplace

A Claude Code plugin marketplace for Frappe Framework and ERPNext development. This repository contains one or more plugins optimized for Frappe/ERPNext workflows.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [frappe-fullstack](./plugins/frappe-fullstack) | Comprehensive full-stack development with DocType scaffolding, bench integration, hooks, a bench-error-log monitor, and specialized agents for backend, classic frontend, React SPA, React Native, ERPNext customization, debugging, planning, and Git workflows |

## Installation

```bash
# Clone this marketplace
git clone https://github.com/UnityAppSuite/frappe-claude.git

# Add the marketplace (inside Claude Code)
/plugin marketplace add ./frappe-claude

# Install the plugin
/plugin install frappe-fullstack@frappe-claude
```

On first install you will be prompted for `bench_path`, `default_site`, and (optionally) `python_path`. These values are reused by the plugin's hooks and the bench-error-log monitor.

## Marketplace Structure

```
frappe-claude/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace manifest
├── plugins/
│   └── frappe-fullstack/         # Full-stack Frappe plugin
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── agents/               # 11 specialized agents
│       ├── commands/             # 9 user-typed slash commands
│       ├── skills/               # 13 model-invoked skills
│       ├── hooks/hooks.json      # SessionStart + PostToolUse
│       ├── monitors/monitors.json# Background bench-error-log tail
│       └── scripts/              # Hook scripts
└── README.md
```

## Plugins Overview

### frappe-fullstack

A comprehensive plugin for Frappe/ERPNext development featuring:

- **11 Agents** — `doctype-architect`, `frappe-backend`, `frappe-frontend`, `frappe-custom-frontend`, `react-spa-frontend`, `react-native-frontend`, `erpnext-customizer`, `frappe-debugger`, `frappe-reviewer`, `frappe-planner`, `github-workflow`
- **9 Slash Commands** — `/frappe-fullstack` (multi-agent orchestrator), `/frappe-plan`, `/frappe-doctype-create`, `/frappe-doctype-field`, `/frappe-app`, `/frappe-bench`, `/frappe-test`, `/frappe-perf`, `/frappe-github`
- **13 Skills** — `bench-commands`, `client-scripts`, `doctype-patterns`, `frappe-api`, `react-native-patterns`, `react-spa-patterns`, `server-scripts`, `frappe-debug`, `frappe-review`, `workflow-patterns`, `print-format`, `testing-patterns`, `scheduler-and-jobs`
- **Hooks** — auto-format Python files inside the bench on save; remind to `bench migrate` after DocType JSON or `hooks.py` edits; inject bench/site context at session start
- **Monitors** — tails `web.error.log` + `worker.error.log` and a filtered `web.log` (warnings, errors, 4xx/5xx, slow requests) whenever the `frappe-debug` skill is invoked, so the debugger agent sees both errors and problem requests live

#### Git Workflow Conventions
- Branch naming: `{type}/{task-id}-{description}` (e.g., `feature/123-payment-api`)
- Clean commits without co-author or generated footers
- PR creation with proper formatting

[View full documentation](./plugins/frappe-fullstack/README.md)

## Adding New Plugins

Per the [current plugin spec](https://code.claude.com/docs/en/plugins-reference#plugin-directory-structure), `skills/` (with `<name>/SKILL.md`) is preferred over `commands/` for new component-style plugins; `commands/` is reserved for user-typed entry points.

1. Create a directory under `plugins/`:
   ```
   plugins/my-plugin/
   ├── .claude-plugin/
   │   └── plugin.json     # Manifest (name required, version optional)
   ├── skills/             # Model-invoked SKILL.md folders
   ├── commands/           # User-typed slash commands (.md)
   ├── agents/             # Subagent definitions (.md with frontmatter)
   ├── hooks/hooks.json    # Optional event handlers
   └── monitors/monitors.json  # Optional background watchers
   ```
2. Add an entry to `.claude-plugin/marketplace.json`.
3. Validate with `claude plugin validate .`.
4. Submit a pull request.

Omit `version` from `plugin.json` if you want every commit to ship to users automatically (uses git SHA). Pin a `version` only if you intend to bump it on every release.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add or modify plugins
4. Run `claude plugin validate .`
5. Test with `claude --plugin-dir ./plugins/<your-plugin>`
6. Submit a pull request

## License

MIT License

## Resources

- [Frappe Framework Documentation](https://frappeframework.com/docs)
- [ERPNext Documentation](https://docs.erpnext.com)
- [Claude Code Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Plugin Marketplace Reference](https://code.claude.com/docs/en/plugin-marketplaces)
- [Plugin Reference](https://code.claude.com/docs/en/plugins-reference)
