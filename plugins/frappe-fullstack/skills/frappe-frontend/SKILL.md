---
name: frappe-frontend
description: Invoke the Frappe frontend agent for client-side JavaScript development including form scripts, dialogs, list views, and UI customization
argument-hint: "task description"
context: fork
agent: frappe-fullstack:frappe-frontend
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Frappe Frontend Development

You are working on a Frappe/ERPNext frontend task.

## Task

$ARGUMENTS

## Context

- This is client-side JavaScript for Frappe Desk
- Focus on: form scripts, custom buttons, dialogs, field handlers, list views, frappe.call
- Use async/await over callbacks, arrow functions for field handlers
- Wrap all user-facing strings with `__()`

## Post-Implementation

After completing the task, remind the user to:
1. Run `bench build --app <app>` if new files were created
2. Run `bench --site <site> clear-cache`
3. Hard refresh browser with Ctrl+Shift+R
