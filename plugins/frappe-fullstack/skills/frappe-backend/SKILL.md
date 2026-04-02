---
name: frappe-backend
description: Invoke the Frappe backend agent for server-side Python development including controllers, APIs, database operations, and background jobs
argument-hint: "task description"
context: fork
agent: frappe-fullstack:frappe-backend
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Frappe Backend Development

You are working on a Frappe/ERPNext backend task.

## Task

$ARGUMENTS

## Context

- Detect site from `sites/currentsite.txt` if available
- Focus on server-side Python: controllers, whitelisted APIs, database operations, background jobs, scheduled tasks
- Follow Frappe coding conventions (import order, error handling, API response structure)
- Use `frappe.log_error()` for logging, NEVER `frappe.logger`

## Post-Implementation

After completing the task, remind the user to:
1. Run `bench --site <site> migrate` if DocType changed
2. Run `bench --site <site> clear-cache`
3. Run tests with `bench --site <site> run-tests --module <module>`
