# Frappe Full Stack Plugin for Claude Code

A comprehensive Claude Code plugin for Frappe Framework and ERPNext full-stack development. This plugin provides specialized agents, skills, and commands for efficient Frappe/ERPNext development.

## Features

- **DocType Development**: Scaffold complete DocTypes with JSON, controllers, and client scripts
- **Specialized Agents**: AI agents for backend, frontend, and ERPNext customization
- **Bench Integration**: Safe execution of bench CLI commands
- **Skills**: Auto-invoked knowledge for Frappe patterns and APIs
- **ERPNext Support**: Customization patterns for ERPNext modules

## Installation

### From GitHub (Recommended)

```bash
# Clone the marketplace repository
git clone https://github.com/UnityAppSuite/frappe-claude.git

# Add the marketplace
/plugin marketplace add ./frappe-claude

# Install the plugin
/plugin install frappe-fullstack
```

### From Local Directory

```bash
# Add the marketplace (if already cloned)
/plugin marketplace add /path/to/frappe-claude

# Install the plugin
/plugin install frappe-fullstack
```

## Components

### Slash Commands

#### Agent Invocation Commands
| Command | Description |
|---------|-------------|
| `/frappe-backend` | Invoke backend agent for Python/server-side development |
| `/frappe-frontend` | Invoke frontend agent for JavaScript/client-side development |
| `/frappe-fullstack` | Orchestrate multiple agents for complete feature development |
| `/frappe-erpnext` | Invoke ERPNext customizer for extending ERPNext |
| `/frappe-debug` | Invoke debugger agent for troubleshooting |
| `/frappe-plan` | Create comprehensive implementation plan and save to file |

#### Scaffolding Commands
| Command | Description |
|---------|-------------|
| `/frappe-doctype-create` | Create a new DocType with complete scaffolding |
| `/frappe-doctype-field` | Add, modify, or remove DocType fields |
| `/frappe-app` | Create a new Frappe application |

#### Utility Commands
| Command | Description |
|---------|-------------|
| `/frappe-bench` | Execute bench commands safely |
| `/frappe-test` | Run Frappe tests with various options |
| `/frappe-github` | Git workflows - branches, commits, PRs |

### Specialized Agents

| Agent | Description |
|-------|-------------|
| `doctype-architect` | Design DocTypes and data models |
| `frappe-backend` | Server-side Python development |
| `frappe-frontend` | Client-side JavaScript development |
| `erpnext-customizer` | ERPNext customization patterns |
| `frappe-debugger` | Debug and troubleshoot issues |
| `frappe-planner` | Strategic planning and architecture design |
| `github-workflow` | Git/GitHub workflows with team conventions |

### Skills (Auto-Invoked)

| Skill | Triggers When |
|-------|---------------|
| `doctype-patterns` | Creating/modifying DocTypes |
| `frappe-api` | Working with Frappe APIs |
| `bench-commands` | Running bench CLI commands |
| `client-scripts` | Writing client-side JavaScript |
| `server-scripts` | Writing server-side Python |

## Usage Examples

### Agent Invocation Commands

#### Backend Development
```
/frappe-backend Create a whitelisted API to fetch customer outstanding balance with credit limit check
```

#### Frontend Development
```
/frappe-frontend Add a custom button to Sales Invoice that opens a dialog for scheduling delivery
```

#### Full-Stack Feature
```
/frappe-fullstack Build a customer feedback system with ratings, categories, follow-up actions, and email notifications
```

#### ERPNext Customization
```
/frappe-erpnext Add approval workflow to Purchase Orders with manager approval for amounts over 10000
```

#### Debug Issues
```
/frappe-debug Getting "Permission denied" error when trying to submit Sales Invoice as Sales User
```

#### Plan New Feature
```
/frappe-plan Customer feedback system with ratings, categories, and follow-up tracking
```
This will:
1. Ask where to save the plan (current directory, docs/, .claude/, or custom path)
2. Explore existing codebase patterns
3. Ask clarifying questions about requirements
4. Generate comprehensive implementation plan with:
   - Requirements and user stories
   - Technical design (DocTypes, APIs, UI)
   - Phased task breakdown
   - Testing and deployment strategy
5. Save plan as markdown file

#### Git/GitHub Workflow
```
/frappe-github create branch
```
This will:
1. Ask for branch type (feature, bugfix, hotfix, refactor, docs)
2. Ask for task ID (e.g., Jira ticket, GitHub issue number)
3. Ask for brief description (1-3 words)
4. Create branch from default branch with format: `{type}/{task-id}-{description}`
   - Example: `feature/123-payment-gateway`, `bugfix/456-invoice-fix`

```
/frappe-github commit
```
This will:
1. Show current changes (staged/unstaged)
2. Ask for commit message
3. Create commit WITHOUT co-author or generated footers

```
/frappe-github create pr
```
This will:
1. Push branch to remote
2. Create PR with proper title and description
3. Return PR URL

### Scaffolding Commands

#### Create a New DocType

```
/frappe-doctype-create "Project Task" my_module
```

This will:
1. Create DocType directory structure
2. Generate JSON definition with fields
3. Create Python controller with lifecycle hooks
4. Create JavaScript client script
5. Create test file

#### Add Fields to Existing DocType

```
/frappe-doctype-field "Sales Order" add custom_priority Select "Low\nMedium\nHigh"
```

#### Create New App

```
/frappe-app my_custom_app --title "My Custom App" --module Core
```

### Utility Commands

#### Run Bench Commands

```
/frappe-bench migrate --site mysite.local
/frappe-bench build --app my_app
/frappe-bench clear-cache
```

#### Run Tests

```
/frappe-test my_app --coverage
/frappe-test --doctype "Sales Invoice"
```

## Agent Orchestration

### How It Works

The plugin provides two levels of agent invocation:

#### 1. Direct Agent Commands
Use `/frappe-backend`, `/frappe-frontend`, `/frappe-erpnext`, or `/frappe-debug` to invoke a specific agent:

```
User: /frappe-backend Create an API to calculate tax
      ↓
Claude spawns frappe-backend agent
      ↓
Agent analyzes, implements, returns code
      ↓
Claude presents solution to user
```

#### 2. Multi-Agent Orchestration (`/frappe-fullstack`)
The `/frappe-fullstack` command coordinates multiple agents in parallel:

```
User: /frappe-fullstack Build a complete feedback system
      ↓
┌─────────────────────────────────────────────────────┐
│              PARALLEL EXECUTION                      │
├─────────────────┬─────────────────┬─────────────────┤
│ doctype-architect│ frappe-backend  │ frappe-frontend │
│ • Design schema │ • Controllers   │ • Form scripts  │
│ • Field types   │ • APIs          │ • Dialogs       │
│ • Relationships │ • Validation    │ • Buttons       │
└─────────────────┴─────────────────┴─────────────────┘
      ↓
Claude merges outputs, creates files
      ↓
Complete feature ready
```

#### 3. Automatic Agent Selection
Even without explicit commands, Claude automatically delegates to appropriate agents based on task description:

```
User: "Add validation to check credit limit before order"
      ↓
Claude recognizes this matches frappe-backend expertise
      ↓
Spawns frappe-backend agent automatically
```

### Agent Capabilities Matrix

| Agent | Python | JavaScript | DocType | ERPNext | Debug | Planning |
|-------|--------|------------|---------|---------|-------|----------|
| doctype-architect | - | - | ✓✓✓ | ✓ | - | - |
| frappe-backend | ✓✓✓ | - | ✓ | ✓ | ✓ | - |
| frappe-frontend | - | ✓✓✓ | ✓ | ✓ | - | - |
| erpnext-customizer | ✓✓ | ✓ | ✓ | ✓✓✓ | - | - |
| frappe-debugger | ✓ | ✓ | ✓ | ✓ | ✓✓✓ | - |
| frappe-planner | ✓ | ✓ | ✓✓ | ✓✓ | - | ✓✓✓ |

## Agent Examples

### DocType Design
Ask Claude to design a DocType:
```
Design a DocType for tracking customer feedback with ratings, categories, and follow-up actions
```
Claude will use the `doctype-architect` agent to:
- Analyze requirements
- Select appropriate field types
- Design relationships
- Create complete JSON definition

### Backend Development
Ask for backend logic:
```
Add validation to ensure order total doesn't exceed customer credit limit
```
Claude will use the `frappe-backend` agent for:
- Controller hook implementation
- Database queries
- Error handling

### ERPNext Customization
Ask for ERPNext customization:
```
Add a custom field to Sales Invoice that tracks the sales channel
```
Claude will use the `erpnext-customizer` agent for:
- Custom field creation
- Hooks configuration
- Fixtures setup

### Feature Planning
Plan before implementing:
```
/frappe-plan Inventory reorder system with automatic purchase order generation
```
Claude will use the `frappe-planner` agent to:
- Gather and clarify requirements
- Analyze existing codebase patterns
- Design data model and architecture
- Create phased implementation tasks
- Save comprehensive plan to markdown file

## Directory Structure

```
frappe-fullstack/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── commands/
│   ├── frappe-doctype-create.md # Create DocType command
│   ├── frappe-doctype-field.md  # Manage fields command
│   ├── frappe-bench.md          # Bench CLI command
│   ├── frappe-test.md           # Run tests command
│   ├── frappe-app.md            # Create app command
│   ├── frappe-backend.md        # Invoke backend agent
│   ├── frappe-frontend.md       # Invoke frontend agent
│   ├── frappe-fullstack.md      # Multi-agent orchestration
│   ├── frappe-erpnext.md        # Invoke ERPNext agent
│   ├── frappe-debug.md          # Invoke debugger agent
│   └── frappe-plan.md           # Create implementation plan
├── agents/
│   ├── doctype-architect.md     # DocType design agent
│   ├── frappe-backend.md        # Backend development
│   ├── frappe-frontend.md       # Frontend development
│   ├── erpnext-customizer.md    # ERPNext customization
│   ├── frappe-debugger.md       # Debugging agent
│   └── frappe-planner.md        # Strategic planning agent
├── skills/
│   ├── doctype-patterns/
│   │   └── SKILL.md             # DocType patterns
│   ├── frappe-api/
│   │   └── SKILL.md             # API reference
│   ├── bench-commands/
│   │   └── SKILL.md             # Bench CLI reference
│   ├── client-scripts/
│   │   └── SKILL.md             # Client JS patterns
│   └── server-scripts/
│       └── SKILL.md             # Server Python patterns
└── README.md
```

## Skill Triggers

Skills are automatically invoked by Claude based on context:

- **doctype-patterns**: Triggered when discussing DocTypes, fields, or data modeling
- **frappe-api**: Triggered for `frappe.get_doc`, `frappe.db`, `frappe.call`
- **bench-commands**: Triggered for `bench` CLI operations
- **client-scripts**: Triggered for form events, dialogs, UI customization
- **server-scripts**: Triggered for controllers, APIs, background jobs

## Frappe Version Compatibility

This plugin is designed for:
- Frappe Framework v14+
- ERPNext v14+

Most patterns are backward compatible with v13.

## Best Practices

### DocType Development
1. Use singular names: "Customer" not "Customers"
2. Follow Title Case: "Sales Invoice"
3. Use snake_case for fieldnames: `customer_name`

### Code Organization
1. Keep controllers focused on business logic
2. Use separate utility files for shared functions
3. Write tests alongside features

### ERPNext Customization
1. Never modify core ERPNext files
2. Use hooks and custom fields
3. Export customizations as fixtures

## Troubleshooting

### Plugin Not Loading
```bash
# Check if plugin is installed
/plugin list

# Reinstall if needed
/plugin uninstall frappe-fullstack
/plugin install frappe-fullstack
```

### Commands Not Working
1. Ensure you're in a Frappe bench directory
2. Check that site is set: `bench use mysite.local`
3. Verify app structure is correct

### Agents Not Invoked
Agents are invoked based on task context. You can explicitly request:
```
Use the frappe-backend agent to help me create an API endpoint
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add/modify components
4. Test with Claude Code
5. Submit pull request

## License

MIT License

## Credits

Created for the Frappe Framework community to enhance development productivity with Claude Code.

## Resources

- [Frappe Framework Documentation](https://frappeframework.com/docs)
- [ERPNext Documentation](https://docs.erpnext.com)
- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
