---
name: frappe-bench
description: Execute Frappe Bench CLI commands safely with site awareness and common operation shortcuts
argument-hint: "command --site sitename"
allowed-tools: Bash, Read, Grep, Glob
---

# Execute Bench Command

Safely execute Frappe Bench CLI commands with proper site context and validation.

## Arguments

Parse the user's input: $ARGUMENTS

Common commands: `migrate`, `build`, `clear-cache`, `console`, `start`, `update`, `backup`, `restore`

## Process

### Step 1: Detect Environment

```bash
# Check if we're in a bench directory
if [ -f "sites/apps.txt" ]; then echo "Bench directory found: $(pwd)"; fi

# List available sites
ls sites/ | grep -v "apps.txt\|common_site_config.json\|assets"

# Check default site
cat sites/currentsite.txt 2>/dev/null || echo "No default site set"
```

### Step 2: Execute Command

Based on the requested operation:

| Task | Command |
|------|---------|
| Start dev server | `bench start` |
| Migrate database | `bench --site <site> migrate` |
| Clear cache | `bench --site <site> clear-cache` |
| Build assets | `bench build` or `bench build --app <app>` |
| Backup site | `bench --site <site> backup --with-files` |
| Python console | `bench --site <site> console` |
| MySQL console | `bench --site <site> mariadb` |
| Run tests | `bench --site <site> run-tests` |
| Check health | `bench --site <site> doctor` |
| Export fixtures | `bench --site <site> export-fixtures` |
| Full update | `bench update` |

### Safety Guidelines

**Destructive Commands (Require Confirmation):**
- `drop-site` — Deletes entire site
- `reinstall` — Drops and recreates database
- `restore` — Overwrites current data
- `reset` — Resets to fresh install

Before running destructive commands:
1. Confirm with user
2. Suggest backup first
3. Check for active users on production

## Error Handling

| Error | Solution |
|-------|----------|
| Site not found | Check `ls sites/` |
| Module not found | `bench setup env && pip install -e apps/frappe` |
| Migration failed | `tail -100 logs/frappe.log`, try `--skip-failing` |
| Build failed | `rm -rf node_modules && yarn install && bench build` |

## Output

After command execution:
1. Show command output
2. Report success/failure
3. Suggest next steps if applicable
