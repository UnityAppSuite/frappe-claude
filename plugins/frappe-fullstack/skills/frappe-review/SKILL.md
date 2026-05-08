---
description: Review Frappe/ERPNext code changes for framework idioms, security, permission correctness, and performance. Use when the user says "review", "review my changes", "review this PR", "code review", "check this PR", or pastes a github.com/*/pull/* URL — even with no other context. Also when reviewing a specific file, controller, API, DocType JSON, client script, or ERPNext customization.
---

# Frappe Review

Triage Frappe/ERPNext changes before they ship. This skill gathers the diff and tooling output, loads the relevant reference rules, then hands off to the `frappe-fullstack:frappe-reviewer` agent for the actual line-by-line review.

## Two modes

### Mode A — Local diff (default)

When the user asks to review without naming a target, review the working tree:

```bash
git -C ${user_config.bench_path} diff HEAD --stat
git -C ${user_config.bench_path} diff HEAD
```

Override only when explicit:

| User says | Use |
|-----------|-----|
| "review my last commit" | `git show HEAD` |
| "review the branch" | `git diff $(git merge-base HEAD main)...HEAD` |
| "review `path/to/file.py`" | `git diff HEAD -- <path>` (and read the full file if context is needed) |

### Mode B — GitHub PR

When the user pastes a GitHub PR URL (`https://github.com/{owner}/{repo}/pull/{n}`) or says "review PR #N":

```bash
gh pr view <url-or-number> --json number,title,body,author,baseRefName,headRefName,headRefOid,files
gh pr diff <url-or-number>
# For files where the diff alone is ambiguous:
gh pr view <url-or-number> --json files -q '.files[].path' | while read -r p; do
  gh api "repos/{owner}/{repo}/contents/$p?ref=<headRefOid>" -H "Accept: application/vnd.github.raw"
done
```

Authentication: `gh` uses the user's existing `gh auth login` credentials, or `GH_TOKEN` / `GITHUB_TOKEN` from env. Do not prompt the user for tokens.

**Posting back to GitHub is opt-in.** Do NOT post the review as a PR comment unless the user explicitly says "post the review", "comment on the PR", or similar. By default, surface the review in the chat only. When the user does ask to post:

```bash
gh pr comment <url-or-number> --body-file <(printf '%s' "<review markdown>")
```

## Workflow

1. **Frame the diff**
   - Mode A: `git diff HEAD --stat`. Mode B: `gh pr view --json files`.
   - If empty, ask the user to point to what they want reviewed.
   - Categorize touched files:

     | Pattern | Domain | Reference to read |
     |---------|--------|-------------------|
     | `*.py` (controllers, APIs, hooks, patches) | Frappe Python | `references/frappe-python.md` |
     | `*.json` inside a `doctype/` path | DocType schema | `references/doctype-json.md` |
     | `*.js`, `*.jsx`, `*.ts`, `*.tsx`, `*.vue` | Frontend | `references/frontend.md` |
     | `*.html` (Jinja) | Templates | `references/frappe-python.md` (Jinja section) |
     | `hooks.py`, `patches/`, `fixtures/` | Frappe infra | `references/frappe-python.md` |
     | `*.css`, `*.scss` | Style | inline rules in `references/frontend.md` |
     | Build / config (`pyproject.toml`, `package.json`, `tsconfig.json`, lockfiles) | Skip unless obviously broken | — |

   - **Always** apply `references/security.md` to every file regardless of type.

2. **Cheap tooling first** (skip whatever isn't installed; never block on tooling)
   ```bash
   # Python — only on changed .py files
   files=$(git diff HEAD --name-only --diff-filter=AM | grep '\.py$')
   [ -n "$files" ] && echo "$files" | xargs -r ruff check 2>/dev/null
   [ -n "$files" ] && echo "$files" | xargs -r ruff format --check 2>/dev/null

   # JS/TS — only when the touched app has its own package.json / lint config
   git diff HEAD --name-only --diff-filter=AM | grep -E '\.(js|jsx|ts|tsx|vue)$'
   ```
   Capture findings — the reviewer agent should not re-flag what tooling already caught.

3. **Note migration / fixture risk**
   ```bash
   git diff HEAD --name-only | grep -E '(doctype/.*\.json|patches\.txt|fixtures/|hooks\.py)$'
   ```
   Any hit means the reviewer must check for a corresponding patch or `after_migrate` step.

4. **Hand off to the reviewer agent**

   Invoke `frappe-fullstack:frappe-reviewer` with:
   - The full unified diff (`git diff HEAD` or `gh pr diff`)
   - Mode (A: local diff / B: PR `<url>`)
   - The list of touched files grouped by category and the reference files that apply
   - Any `ruff` / `eslint` findings already known (so the agent ignores them)
   - The bench root and default site from `${user_config.bench_path}` and `${user_config.default_site}` for cross-file lookups

   The agent reads the relevant reference files itself — do not copy rule text into the prompt.

5. **Surface the report**

   The agent returns a single structured report (severity buckets + verdict + What's Done Well + file-by-file table). Surface it verbatim. Do not summarize or rewrite — the user needs the citations intact.

## What this skill does NOT do

- Does not apply fixes. Both the skill and the agent are read-only by tool config.
- Does not run the test suite. If the reviewer flags missing tests, invoke `/frappe-test` separately.
- Does not commit, push, or open PRs. Use `/frappe-github` after fixes.
- Does not post to GitHub by default. Posting requires an explicit user request.
