---
name: frappe-fullstack
description: Invoke multiple Frappe agents in parallel for full-stack development — coordinates backend, frontend, and architecture agents for complete feature implementation
argument-hint: "feature description"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, AskUserQuestion
effort: high
---

# Frappe Full-Stack Development

Orchestrate multiple specialized agents to build complete features across the full Frappe stack.

## Request

$ARGUMENTS

## Orchestration Strategy

This command coordinates multiple agents working in parallel for comprehensive feature development.

### Phase 1: Understanding & Planning

First, understand the scope:

1. **Analyze the Feature Request**
   - What data needs to be stored? (DocType design)
   - What backend logic is needed? (Controllers, APIs)
   - What UI/UX is required? (Form scripts, dialogs)
   - Is ERPNext integration needed? (Customizations, hooks)

2. **Create Task List**
   Use TaskCreate to track:
   - [ ] DocType/data model design
   - [ ] Backend implementation
   - [ ] Frontend implementation
   - [ ] Integration/hooks (if needed)
   - [ ] Testing

### Phase 2: Parallel Agent Invocation

Launch agents in parallel using multiple Agent tool calls in a single message.

**IMPORTANT:** Agent names MUST be fully qualified with plugin prefix:
- `frappe-fullstack:doctype-architect`
- `frappe-fullstack:frappe-backend`
- `frappe-fullstack:frappe-frontend`
- `frappe-fullstack:erpnext-customizer`

```
+-----------------+-----------------+-------------------------+
| doctype-        | frappe-backend  | frappe-frontend         |
| architect       |                 |                         |
|                 |                 |                         |
| - Design schema | - Controllers   | - Form scripts          |
| - Field types   | - APIs          | - Dialogs               |
| - Relationships | - Validation    | - Field handlers        |
| - Permissions   | - Background    | - Custom buttons        |
+-----------------+-----------------+-------------------------+
```

### Phase 3: Integration

After parallel agents complete:

1. **Merge Outputs** — Combine code, resolve conflicts, ensure API names match
2. **Add ERPNext Integration** (if needed) — Spawn `frappe-fullstack:erpnext-customizer`
3. **Write Files** to appropriate locations

### Phase 4: Finalization

1. Update `hooks.py` if needed
2. Run `bench --site <site> migrate`
3. Run `bench build --app <app>`
4. Run `bench --site <site> clear-cache`

## Agent Coordination Tips

1. **Share Context**: Pass DocType definitions from architect to other agents
2. **Consistent Naming**: Ensure API method names match between frontend/backend
3. **Handle Dependencies**: Backend APIs must exist before frontend can call them
4. **Test Incrementally**: Verify each layer works before integrating

## Output Checklist

After completion, verify:

- [ ] DocType JSON created/modified
- [ ] Python controller implemented
- [ ] JavaScript form script implemented
- [ ] APIs accessible from frontend
- [ ] hooks.py updated (if needed)
- [ ] Migration successful
- [ ] Assets built
- [ ] Cache cleared
- [ ] Feature tested in browser
