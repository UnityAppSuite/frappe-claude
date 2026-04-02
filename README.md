# Frappe Claude - Plugin Marketplace

A Claude Code plugin marketplace for Frappe Framework and ERPNext development. Provides specialized AI agents, skills, safety hooks, and cross-session memory for full-stack Frappe/ERPNext workflows.

## Quick Start

```bash
# Add the marketplace to Claude Code
claude plugin marketplace add https://github.com/UnityAppSuite/frappe-claude

# Install the plugin
claude plugin install frappe-fullstack

# Start using
/frappe-backend Create a whitelisted API for customer dashboard
/frappe-fullstack Build a feedback system with ratings and notifications
/commit
```

## Available Plugins

| Plugin | Version | Description |
|--------|---------|-------------|
| [frappe-fullstack](./plugins/frappe-fullstack) | 2.0.0 | Full-stack Frappe/ERPNext development with 10 agents, 21 skills, hooks, and memory |

## What's Included

### 10 Specialized Agents

| Agent | Purpose | Color |
|-------|---------|-------|
| `doctype-architect` | DocType design and data modeling | purple |
| `frappe-backend` | Server-side Python (controllers, APIs, jobs) | blue |
| `frappe-frontend` | Client-side JavaScript (forms, dialogs, UI) | green |
| `frappe-custom-frontend` | Modern React/Vue frontends with Doppio | cyan |
| `erpnext-customizer` | ERPNext extensions (custom fields, hooks, overrides) | orange |
| `frappe-debugger` | Error analysis, log investigation, troubleshooting | red |
| `frappe-planner` | Strategic planning, architecture design | yellow |
| `github-workflow` | Branch creation, clean commits, PR management | cyan |
| `react-native-frontend` | React Native / Expo mobile apps | pink |
| `react-spa-frontend` | React SPA (TanStack Query, Jotai, Refine) | green |

### 21 Skills

**9 Agent Fork Skills** — Use `context: fork` for direct agent invocation:
`/frappe-backend`, `/frappe-frontend`, `/frappe-fullstack`, `/frappe-erpnext`, `/frappe-debug`, `/frappe-plan`, `/frappe-github`, `/react-native`, `/react-spa`

**6 Standalone Skills** — Direct execution without agents:
`/frappe-doctype-create`, `/frappe-doctype-field`, `/frappe-app`, `/frappe-bench`, `/frappe-test`, `/commit`

**7 Reference Skills** — Background knowledge auto-loaded by Claude:
`doctype-patterns`, `frappe-api`, `server-scripts`, `client-scripts`, `bench-commands`, `react-native-patterns`, `react-spa-patterns`

### Safety & Automation

- **PreToolUse hooks**: Block destructive bench commands (`drop-site`, `reinstall`, `rm -rf`)
- **Co-author stripping**: Automatically removes `Co-Authored-By` lines from all git commits
- **Environment detection**: Auto-detects bench directory and available sites on session start
- **Cross-session memory**: Agents remember project conventions across sessions

### Parallel Agent Orchestration

`/frappe-fullstack` spawns multiple agents simultaneously for complete feature implementation:

```
/frappe-fullstack Build a customer feedback system

         ┌────────────────┐  ┌──────────────┐  ┌───────────────┐
         │ doctype-       │  │ frappe-      │  │ frappe-       │
         │ architect      │  │ backend      │  │ frontend      │
         │                │  │              │  │               │
         │ Design schema  │  │ Controllers  │  │ Form scripts  │
         │ Field types    │  │ APIs         │  │ Dialogs       │
         │ Relationships  │  │ Validation   │  │ Buttons       │
         └───────┬────────┘  └──────┬───────┘  └───────┬───────┘
                 │                  │                   │
                 └──────────────────┴───────────────────┘
                                    │
                           Merge & integrate
```

## Marketplace Structure

```
frappe-claude/
├── .claude-plugin/
│   └── marketplace.json         # Marketplace manifest
├── plugins/
│   └── frappe-fullstack/        # Full-stack Frappe plugin (v2.0.0)
│       ├── .claude-plugin/
│       │   └── plugin.json      # Plugin manifest with userConfig
│       ├── settings.json        # Default agent configuration
│       ├── hooks/               # Safety hooks
│       ├── scripts/             # Hook scripts
│       ├── agents/              # 10 specialized agents
│       └── skills/              # 21 skills (fork, standalone, reference)
└── README.md
```

## Adding New Plugins

1. Create a new directory under `plugins/`
2. Add the required structure:
   ```
   plugins/my-plugin/
   ├── .claude-plugin/
   │   └── plugin.json
   ├── agents/
   ├── skills/
   └── hooks/
   ```
3. Update `.claude-plugin/marketplace.json` to include the new plugin
4. Test locally: `claude --plugin-dir ./plugins/my-plugin`
5. Validate: `claude plugin validate ./plugins/my-plugin`
6. Submit a pull request

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add or modify plugins
4. Test with Claude Code
5. Submit a pull request

## License

MIT License

## Resources

- [Frappe Framework Documentation](https://frappeframework.com/docs)
- [ERPNext Documentation](https://docs.erpnext.com)
- [Claude Code Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Agent Skills Open Standard](https://agentskills.io)
