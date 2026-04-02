# Frappe Full Stack Plugin for Claude Code

A comprehensive Claude Code plugin for Frappe Framework and ERPNext full-stack development. Provides 10 specialized AI agents, 21 skills, safety hooks, and cross-session memory for efficient Frappe/ERPNext development.

## What's New in v2.0.0

- **Modern skill format**: Migrated from legacy `commands/` to `skills/<name>/SKILL.md` with proper frontmatter
- **Agent forking**: Skills use `context: fork` + `agent:` for direct agent invocation (no manual Task tool spawning)
- **Cross-session memory**: Agents remember project conventions, site names, and patterns across sessions via `memory: project`
- **Skill preloading**: Each agent auto-loads relevant reference skills (e.g., backend agent gets `server-scripts` + `frappe-api`)
- **Safety hooks**: PreToolUse hooks block destructive bench commands and strip Co-Authored-By lines from commits
- **Environment auto-detection**: SessionStart hook detects bench directory, current site, and available sites
- **Commit skill**: `/commit` creates clean commits without AI attribution
- **userConfig**: Configurable bench path, site name, and app name at plugin enable time

## Installation

### From GitHub (Recommended)

```bash
# Add the marketplace
claude plugin marketplace add https://github.com/UnityAppSuite/frappe-claude

# Install the plugin
claude plugin install frappe-fullstack
```

### From Local Clone

```bash
git clone https://github.com/UnityAppSuite/frappe-claude.git

# Add as local marketplace
/plugin marketplace add ./frappe-claude

# Install
/plugin install frappe-fullstack
```

### Plugin Configuration

On first enable, you'll be prompted for optional settings:

| Setting | Description | Example |
|---------|-------------|---------|
| `BENCH_PATH` | Path to Frappe bench directory | `~/frappe-bench` |
| `SITE_NAME` | Default Frappe site name | `mysite.localhost` |
| `APP_NAME` | Primary app being developed | `my_custom_app` |

These are available as `${user_config.BENCH_PATH}` in skills and as `CLAUDE_PLUGIN_OPTION_BENCH_PATH` environment variables.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER / CLAUDE                             │
│                                                                  │
│  /frappe-backend    /frappe-fullstack    /commit   /frappe-bench │
│       │                    │                │           │        │
│  ┌────▼────┐    ┌──────────▼──────────┐   │      standalone    │
│  │ context │    │   inline (no fork)   │   │       skill       │
│  │  fork   │    │   spawns parallel    │   │                    │
│  │         │    │   Agent calls        │   │                    │
│  └────┬────┘    └──┬──────┬──────┬────┘   │                    │
│       │            │      │      │        │                    │
│  ┌────▼────┐  ┌────▼──┐┌─▼───┐┌─▼────┐   │                    │
│  │ frappe- │  │doctype││frappe││frappe │   │                    │
│  │ backend │  │archit.││back- ││front- │   │                    │
│  │ agent   │  │ agent ││end   ││end    │   │                    │
│  └─────────┘  └───────┘└─────┘└───────┘   │                    │
│       │            │      │      │        │                    │
│  ┌────▼────────────▼──────▼──────▼────────▼────────────────┐   │
│  │              PRELOADED SKILLS (auto-injected)            │   │
│  │  server-scripts  frappe-api  doctype-patterns  etc.      │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    HOOKS LAYER                            │   │
│  │  PreToolUse: strip Co-Authored-By, block destructive cmds│   │
│  │  SessionStart: detect bench env, list sites               │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Agent-delegating skills use `context: fork`** — The skill runs directly inside the agent's context. No intermediate "use the Task tool to spawn..." instructions needed.

2. **`/frappe-fullstack` runs inline (no fork)** — It must spawn multiple agents in parallel, and forked contexts cannot spawn sub-agents. So it runs in the main conversation and uses the `Agent` tool directly.

3. **`frappe-planner` as default agent** — When using `claude --agent frappe-planner`, it can delegate to all other agents via the `Agent` tool (included in its tools list).

4. **Reference skills are `user-invocable: false`** — Pattern/API reference skills don't appear in the `/` menu. Claude loads them automatically when relevant, and agents get them injected via `skills:` preloading.

## Skills Reference

### Agent Fork Skills

These skills use `context: fork` + `agent:` to run directly inside the specified agent's context.

#### `/frappe-backend <task>`
Spawns the `frappe-backend` agent for server-side Python development.
```
/frappe-backend Create a whitelisted API to fetch customer outstanding balance
/frappe-backend Add validation to prevent negative stock quantities
/frappe-backend Create a background job to sync orders from external API
```

#### `/frappe-frontend <task>`
Spawns the `frappe-frontend` agent for client-side JavaScript.
```
/frappe-frontend Add a custom button to Sales Invoice that opens a delivery dialog
/frappe-frontend Show/hide fields based on document type selection
/frappe-frontend Auto-calculate totals when child table qty or rate changes
```

#### `/frappe-erpnext <task>`
Spawns the `erpnext-customizer` agent for ERPNext extensions.
```
/frappe-erpnext Add approval workflow to Purchase Orders over $10,000
/frappe-erpnext Add custom field to Sales Invoice for sales channel tracking
/frappe-erpnext Create override class for custom Stock Entry validation
```

#### `/frappe-debug <issue>`
Spawns the `frappe-debugger` agent for troubleshooting.
```
/frappe-debug Getting "Permission denied" when submitting Sales Invoice as Sales User
/frappe-debug Background job stuck in pending state for over an hour
/frappe-debug Migration failing with column already exists error
```

#### `/frappe-plan <feature>`
Spawns the `frappe-planner` agent for strategic planning.
```
/frappe-plan Customer feedback system with ratings, categories, and follow-ups
/frappe-plan Inventory reorder system with automatic purchase order generation
```
The planner enters Claude's plan mode, asks clarifying questions, explores the codebase, and saves a comprehensive `PLAN.md` to a feature folder.

#### `/frappe-github <operation>`
Spawns the `github-workflow` agent for Git operations. Has `disable-model-invocation: true` so it's only triggered manually.
```
/frappe-github create branch
/frappe-github commit
/frappe-github create pr
```

Branch naming: `{type}/{task-id}-{description}` (e.g., `feat/123-payment-api`)
Commits: **No co-author lines, no AI footers, clean messages.**

#### `/react-native <task>`
Spawns the `react-native-frontend` agent for Expo mobile apps.
```
/react-native Add GPS tracking to the driver journey screen
/react-native Implement attendance marking with camera capture
```

#### `/react-spa <task>`
Spawns the `react-spa-frontend` agent for React SPAs.
```
/react-spa Add a student attendance dashboard page to the parent app
/react-spa Create a new Refine resource for managing transport routes
```

### Multi-Agent Orchestration

#### `/frappe-fullstack <feature>`
Runs **inline** (not forked) and spawns multiple agents in parallel.
```
/frappe-fullstack Build a customer feedback system with ratings, categories, email notifications
```

**Execution flow:**
```
Phase 1: Analyze requirements, create task list
Phase 2: Spawn agents in parallel
         ├── doctype-architect → design data model
         ├── frappe-backend → controllers, APIs, jobs
         └── frappe-frontend → form scripts, dialogs, buttons
Phase 3: Merge outputs, resolve conflicts
Phase 4: (if needed) Spawn erpnext-customizer for ERPNext integration
Phase 5: Run migrate, build, clear-cache
```

### Standalone Skills

These skills run inline without delegating to an agent.

| Skill | Description |
|-------|-------------|
| `/frappe-doctype-create <name> [module]` | Scaffold complete DocType (JSON, controller, script, tests) |
| `/frappe-doctype-field <name> <action>` | Add, modify, or remove DocType fields |
| `/frappe-app <name>` | Create new Frappe application with full scaffolding |
| `/frappe-bench <command>` | Execute bench commands safely with site awareness |
| `/frappe-test [app] [--doctype name]` | Run tests with filtering and coverage |
| `/commit [message]` | Clean git commits — no co-author, no AI footers |

### Reference Skills (Background Knowledge)

These skills have `user-invocable: false` — they don't appear in `/` autocomplete. Claude loads them automatically when the conversation context matches, and agents receive them via `skills:` preloading.

| Skill | Auto-loaded by Agents | Content |
|-------|-----------------------|---------|
| `doctype-patterns` | doctype-architect, frappe-planner | Field types, naming, permissions, child tables |
| `frappe-api` | All development agents | Document ops, DB queries, REST API, utilities |
| `server-scripts` | frappe-backend, erpnext-customizer, frappe-planner | Controllers, hooks, APIs, background jobs |
| `client-scripts` | frappe-frontend | Form events, dialogs, frappe.call, field manipulation |
| `bench-commands` | frappe-debugger | Site management, builds, migrations, troubleshooting |
| `react-native-patterns` | react-native-frontend | React Query v4, Redux, Expo, navigation, GPS |
| `react-spa-patterns` | react-spa-frontend | TanStack Query v5, Jotai, shadcn/ui, Refine v4 |

## Agents Reference

### Agent Capabilities

| Agent | Model | Effort | Max Turns | Color | Memory | Tools |
|-------|-------|--------|-----------|-------|--------|-------|
| doctype-architect | sonnet | high | 25 | purple | project | Glob, Grep, Read, Edit, Write, Bash |
| frappe-backend | sonnet | high | 30 | blue | project | Glob, Grep, Read, Edit, Write, Bash |
| frappe-frontend | sonnet | high | 30 | green | project | Glob, Grep, Read, Edit, Write, Bash |
| frappe-custom-frontend | sonnet | high | 30 | cyan | project | Glob, Grep, Read, Edit, Write, Bash |
| erpnext-customizer | sonnet | high | 25 | orange | project | Glob, Grep, Read, Edit, Write, Bash |
| frappe-debugger | sonnet | high | 20 | red | project | Bash, Read, Grep, Glob |
| frappe-planner | sonnet | max | 30 | yellow | project | Glob, Grep, Read, Write, Edit, Bash, AskUserQuestion, TodoWrite, EnterPlanMode, ExitPlanMode, Agent |
| github-workflow | sonnet | medium | 15 | cyan | - | Bash, Read, Grep, AskUserQuestion |
| react-native-frontend | sonnet | high | 30 | pink | project | Glob, Grep, Read, Edit, Write, Bash |
| react-spa-frontend | sonnet | high | 30 | green | project | Glob, Grep, Read, Edit, Write, Bash |

### Cross-Session Memory

Agents with `memory: project` maintain a persistent memory directory at `.claude/agent-memory/<agent-name>/`. They automatically:
- Remember project-specific conventions (import styles, naming patterns)
- Track site names and app structure discovered during sessions
- Store patterns learned from code reviews and debugging

The first 200 lines of each agent's `MEMORY.md` are auto-injected into the agent's system prompt on every invocation.

### Agent Invocation Methods

1. **Via slash command**: `/frappe-backend Add a credit limit check` — uses `context: fork`
2. **Natural language**: "Use the backend agent to add validation" — Claude delegates automatically
3. **@-mention**: `@"frappe-backend (agent)"` — guarantees invocation
4. **Main agent mode**: `claude --agent frappe-planner` — planner runs as main thread, can delegate to others

## Hooks

### PreToolUse Hooks (Bash)

Two hooks run on every Bash tool call:

1. **Strip Co-Authored-By** (`scripts/strip-coauthor.sh`): Intercepts `git commit` commands and removes any `Co-Authored-By` lines via `updatedInput`. This is a safety net — even if Claude's system prompt is ignored, the hook catches it.

2. **Block destructive commands**: A prompt hook that denies commands containing `bench drop-site`, `bench destroy-all-sessions`, `bench reinstall`, `rm -rf`, or `bench --force`.

### SessionStart Hook

Auto-detects Frappe bench environment:
- Checks for `sites/common_site_config.json`
- Lists available sites
- Reports current site from `currentsite.txt`
- Injects context via `additionalContext` so Claude knows the environment

## Directory Structure

```
frappe-fullstack/
├── .claude-plugin/
│   └── plugin.json                    # Plugin manifest v2.0.0
├── settings.json                      # Default agent: frappe-planner
├── hooks/
│   └── hooks.json                     # PreToolUse + SessionStart hooks
├── scripts/
│   └── strip-coauthor.sh             # Hook script for commit sanitization
├── agents/                            # 10 specialized AI agents
│   ├── doctype-architect.md           # Data modeling (purple)
│   ├── frappe-backend.md              # Python backend (blue)
│   ├── frappe-frontend.md             # JavaScript frontend (green)
│   ├── frappe-custom-frontend.md      # Doppio/React/Vue (cyan)
│   ├── erpnext-customizer.md          # ERPNext extensions (orange)
│   ├── frappe-debugger.md             # Debugging (red)
│   ├── frappe-planner.md              # Planning + agent delegation (yellow)
│   ├── github-workflow.md             # Git workflows (cyan)
│   ├── react-native-frontend.md       # Expo mobile (pink)
│   └── react-spa-frontend.md         # React SPA (green)
├── skills/
│   │── # Agent fork skills (14)
│   ├── frappe-backend/SKILL.md        # context: fork → frappe-backend
│   ├── frappe-frontend/SKILL.md       # context: fork → frappe-frontend
│   ├── frappe-fullstack/SKILL.md      # inline → multi-agent parallel
│   ├── frappe-erpnext/SKILL.md        # context: fork → erpnext-customizer
│   ├── frappe-debug/SKILL.md          # context: fork → frappe-debugger
│   ├── frappe-plan/SKILL.md           # context: fork → frappe-planner
│   ├── frappe-github/SKILL.md         # context: fork → github-workflow
│   ├── react-native/SKILL.md          # context: fork → react-native-frontend
│   ├── react-spa/SKILL.md             # context: fork → react-spa-frontend
│   ├── commit/SKILL.md                # Clean commits, no AI attribution
│   ├── frappe-bench/SKILL.md          # Bench CLI operations
│   ├── frappe-doctype-create/SKILL.md # DocType scaffolding
│   ├── frappe-doctype-field/SKILL.md  # Field management
│   ├── frappe-app/SKILL.md            # App scaffolding
│   ├── frappe-test/SKILL.md           # Test runner
│   │── # Reference skills (7, user-invocable: false)
│   ├── doctype-patterns/SKILL.md      # DocType field types, naming, permissions
│   ├── frappe-api/SKILL.md            # Python + JS API reference
│   ├── server-scripts/SKILL.md        # Controllers, hooks, background jobs
│   ├── client-scripts/SKILL.md        # Form events, dialogs, frappe.call
│   ├── bench-commands/SKILL.md        # Bench CLI reference
│   ├── react-native-patterns/SKILL.md # RN/Expo patterns
│   └── react-spa-patterns/SKILL.md   # React SPA patterns
└── README.md
```

## Frappe Version Compatibility

- Frappe Framework v14+
- ERPNext v14+
- Most patterns are backward compatible with v13

## Best Practices

### DocType Development
- Singular names: "Customer" not "Customers"
- Title Case: "Sales Invoice"
- snake_case for fieldnames: `customer_name`

### Code Organization
- Controllers focused on business logic
- Separate utility files for shared functions
- Tests alongside features

### ERPNext Customization
- Never modify core ERPNext files
- Use hooks, custom fields, override classes
- Prefer `after_migrate` over fixtures for custom fields

### Git Workflow
- Branch naming: `{type}/{task-id}-{description}`
- Clean commits: no co-author, no AI footers
- Use `/commit` or `/frappe-github commit`

## Troubleshooting

### Plugin Not Loading
```bash
/plugin list                              # Check installed plugins
/plugin uninstall frappe-fullstack        # Remove
/plugin install frappe-fullstack          # Reinstall
/reload-plugins                           # Reload without restart
claude --debug                            # Debug plugin loading
claude plugin validate .                  # Validate plugin structure
```

### Skills Not Appearing
- Slash commands appear when typing `/frappe-` in the prompt
- Reference skills are hidden (`user-invocable: false`) — they load automatically
- Use `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var to increase skill description budget

### Agents Not Invoked
- Agents are auto-selected based on task description
- Force invocation: `@"frappe-backend (agent)" help me with...`
- Check with `/frappe-backend` slash command for guaranteed invocation

### Hooks Not Running
- Use `/hooks` to verify hook configurations
- Check `claude --debug` output for hook loading
- Plugin hooks merge with (don't replace) project hooks

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add/modify components
4. Test locally: `claude --plugin-dir ./plugins/frappe-fullstack`
5. Validate: `claude plugin validate ./plugins/frappe-fullstack`
6. Submit pull request

## License

MIT License

## Resources

- [Frappe Framework Documentation](https://frappeframework.com/docs)
- [ERPNext Documentation](https://docs.erpnext.com)
- [Claude Code Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Agent Skills Open Standard](https://agentskills.io)
