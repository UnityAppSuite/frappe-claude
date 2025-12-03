# Frappe Claude - Plugin Marketplace

A Claude Code plugin marketplace for Frappe Framework and ERPNext development. This repository contains multiple plugins optimized for Frappe/ERPNext workflows.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [frappe-fullstack](./plugins/frappe-fullstack) | Comprehensive full-stack development with DocType scaffolding, bench integration, and specialized agents |

## Installation

```bash
# Clone this marketplace
git clone https://github.com/UnityAppSuite/frappe-claude.git

# Add the marketplace to Claude Code
/plugin marketplace add ./frappe-claude

# List available plugins
/plugin search frappe

# Install a plugin
/plugin install frappe-fullstack
```

## Marketplace Structure

```
frappe-claude/
├── .claude-plugin/
│   └── marketplace.json     # Marketplace manifest
├── plugins/
│   └── frappe-fullstack/    # Full-stack Frappe plugin
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── agents/          # Specialized AI agents
│       ├── commands/        # Slash commands
│       └── skills/          # Auto-invoked skills
└── README.md
```

## Plugins Overview

### frappe-fullstack

A comprehensive plugin for Frappe/ERPNext development featuring:

- **7 Specialized Agents**: doctype-architect, frappe-backend, frappe-frontend, erpnext-customizer, frappe-debugger, frappe-planner, github-workflow
- **12 Slash Commands**: For DocType creation, backend/frontend development, debugging, Git workflows, and more
- **5 Skills**: Auto-invoked knowledge for Frappe patterns, APIs, and best practices

#### Git Workflow Features
- Branch naming: `{type}/{task-id}-{description}` (e.g., `feature/123-payment-api`)
- Clean commits without co-author or generated footers
- PR creation with proper formatting

[View full documentation](./plugins/frappe-fullstack/README.md)

## Adding New Plugins

To add a new plugin to this marketplace:

1. Create a new directory under `plugins/`
2. Add the required plugin structure:
   ```
   plugins/my-plugin/
   ├── .claude-plugin/
   │   └── plugin.json
   ├── commands/
   ├── agents/
   └── skills/
   ```
3. Update `marketplace.json` to include the new plugin
4. Submit a pull request

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
