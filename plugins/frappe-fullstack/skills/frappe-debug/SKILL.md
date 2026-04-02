---
name: frappe-debug
description: Invoke the Frappe debugger agent for troubleshooting errors, analyzing logs, debugging permissions, and investigating performance issues
argument-hint: "error or issue description"
context: fork
agent: frappe-fullstack:frappe-debugger
allowed-tools: Bash, Read, Grep, Glob
---

# Frappe Debug & Troubleshoot

You are debugging a Frappe/ERPNext issue.

## Issue

$ARGUMENTS

## Context

- Check logs, database, permissions, cache
- Provide clear diagnosis with root cause
- Suggest step-by-step fix with verification commands
- Focus on investigation — read-only approach unless fix is clear

## Diagnostic Priority

1. Check error logs: `tail -100 logs/frappe.log`
2. Identify error type from traceback
3. Check permissions if PermissionError
4. Check Redis and background workers if job-related
5. Verify recent code changes with `git log`
