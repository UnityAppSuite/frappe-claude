#!/usr/bin/env bash
# SessionStart hook: emit detected Frappe bench context to Claude.
# Receives event JSON on stdin (ignored). Writes a brief plain-text
# summary to stdout, which Claude Code surfaces as session context.

set -u

bench="${CLAUDE_PLUGIN_OPTION_BENCH_PATH:-}"
site="${CLAUDE_PLUGIN_OPTION_DEFAULT_SITE:-}"

if [ -z "$bench" ] || [ ! -d "$bench" ]; then
  exit 0
fi

frappe_version=""
if [ -f "$bench/apps/frappe/frappe/__init__.py" ]; then
  frappe_version=$(grep -m1 '^__version__' "$bench/apps/frappe/frappe/__init__.py" 2>/dev/null \
    | sed -E 's/.*"([^"]+)".*/\1/')
fi

apps_list=""
if [ -f "$bench/sites/apps.txt" ]; then
  apps_list=$(tr '\n' ' ' < "$bench/sites/apps.txt" | sed 's/ *$//')
fi

site_exists="missing"
if [ -n "$site" ] && [ -d "$bench/sites/$site" ]; then
  site_exists="present"
fi

cat <<EOF
Frappe bench context
- bench_path: $bench
- default_site: ${site:-<unset>} ($site_exists)
- frappe_version: ${frappe_version:-unknown}
- installed_apps: ${apps_list:-<none>}
EOF
