---
name: frappe-erpnext
description: Invoke the ERPNext customizer agent for extending ERPNext with custom fields, hooks, fixtures, and module-specific customizations
argument-hint: "customization description"
context: fork
agent: frappe-fullstack:erpnext-customizer
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# ERPNext Customization

You are customizing ERPNext for specific business requirements.

## Task

$ARGUMENTS

## Context

- This is ERPNext customization (not core modification)
- All changes should be in a custom app
- Prefer `after_migrate` hooks over fixtures for custom fields
- Use override classes when extending stock DocType behavior
- Ensure portability — changes must survive ERPNext upgrades

## Post-Implementation

After completing the task, remind the user to:
1. Run `bench --site <site> migrate`
2. Run `bench --site <site> clear-cache`
3. Export fixtures if applicable: `bench --site <site> export-fixtures --app <app>`
