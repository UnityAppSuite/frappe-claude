---
name: frappe-github
description: Manage Git workflows — create branches, commit changes, push, and create PRs following team conventions
argument-hint: "git operation"
context: fork
agent: frappe-fullstack:github-workflow
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, AskUserQuestion
---

# GitHub Workflow

## Task

$ARGUMENTS

## Conventions

- **Branch naming**: `{type}/{task-id}-{description}` (e.g., `feat/123-payment-api`)
- **Commits**: No co-authored-by lines, no generated footers, clear descriptive messages
- **PRs**: Proper title and description format

## Common Operations

- `create branch` — Ask for task ID and description, create from default branch
- `commit` — Stage changes and commit with descriptive message
- `push` — Push current branch to remote
- `create pr` — Create pull request with proper format
