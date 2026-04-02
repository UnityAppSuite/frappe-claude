---
name: commit
description: Create clean git commits following project conventions. No co-author lines, no generated footers.
argument-hint: "commit message"
allowed-tools: Bash, Read, Grep, Glob
disable-model-invocation: true
---

# Git Commit

Create a clean git commit following project conventions.

## CRITICAL RULES

- **NEVER** add `Co-Authored-By` lines
- **NEVER** add `Generated with Claude Code` footers
- **NEVER** add any AI attribution to commits
- Keep commit messages clear and descriptive
- Focus on the "why" not the "what"

## Process

### Step 1: Check Status

Run `git status` and `git diff --staged` to understand what's being committed.

If nothing is staged, run `git diff` to show unstaged changes and ask the user what to stage.

### Step 2: Review Changes

Analyze the staged changes to understand:
- What was changed and why
- Whether to split into multiple commits
- Whether any sensitive files (.env, credentials) are being committed — warn if so

### Step 3: Draft Commit Message

If the user provided a message via `$ARGUMENTS`, use that directly.

Otherwise, draft a concise commit message:
- **Format**: `type: short description` (e.g., `feat: add credit limit validation`)
- **Types**: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`
- One line, under 72 characters
- Imperative mood ("add" not "added")
- No period at the end

### Step 4: Commit

```bash
git commit -m "the commit message"
```

**DO NOT** append any co-author, attribution, or footer lines.

### Step 5: Confirm

Show the commit hash and summary. Suggest `git push` if appropriate.
