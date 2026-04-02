---
name: frappe-app
description: Create a new Frappe application with complete scaffolding including modules, hooks, and initial structure
argument-hint: "app_name --title Title --module module_name"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Scaffold New Frappe App

Create a new Frappe application with proper structure, configuration, and initial setup.

## Arguments

Parse the user's input: $ARGUMENTS

- **app_name**: Snake_case app name (e.g., `my_custom_app`)
- **--title**: Human-readable title
- **--module**: Initial module name to create
- **--erpnext**: Include ERPNext dependencies

## Process

### Step 1: Verify Environment

```bash
# Must be in bench directory
[ -f "sites/apps.txt" ] && echo "Bench confirmed" || echo "Error: Not in bench"
[ -d "apps/<app_name>" ] && echo "Error: App exists" || echo "OK"
```

### Step 2: Create App

```bash
bench new-app <app_name>
```

### Step 3: Configure hooks.py

Enhance with commented-out patterns for:
- `required_apps`, `fixtures`, `doc_events`
- `scheduler_events`, `website_route_rules`
- `app_include_css/js`, `after_install/before_uninstall`

### Step 4: Create Module (if specified)

```bash
mkdir -p apps/<app_name>/<app_name>/<module_name>
touch apps/<app_name>/<app_name>/<module_name>/__init__.py
```

Update `modules.txt` with module name.

### Step 5: ERPNext Integration (if --erpnext)

Add `required_apps = ["frappe", "erpnext"]` and create `install.py` with `after_install`/`before_uninstall` hooks for custom field setup.

### Step 6: Install on Site

```bash
bench --site <sitename> install-app <app_name>
```

## Output

1. List of files created
2. Next steps: install, create first DocType, start dev server
3. Useful commands: migrate, build, run-tests, export-fixtures
