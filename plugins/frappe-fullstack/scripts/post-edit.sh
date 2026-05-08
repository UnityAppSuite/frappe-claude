#!/usr/bin/env bash
# PostToolUse hook for Write|Edit. Auto-format Python files inside the bench
# and surface a migrate reminder when DocType JSON or hooks.py changes.
#
# Reads event JSON on stdin. Emits human-readable hints on stdout.
# Always exits 0 so a formatting error never blocks Claude.

set -u

bench="${CLAUDE_PLUGIN_OPTION_BENCH_PATH:-}"
site="${CLAUDE_PLUGIN_OPTION_DEFAULT_SITE:-}"

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

file_path=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$file_path" ] && exit 0

case "$file_path" in
  *.py)
    if [ -n "$bench" ] && [[ "$file_path" == "$bench/apps/"* ]]; then
      if command -v ruff >/dev/null 2>&1; then
        ruff format "$file_path" >/dev/null 2>&1 || true
        ruff check --fix --select I "$file_path" >/dev/null 2>&1 || true
      fi
    fi
    ;;
esac

case "$file_path" in
  */doctype/*/*.json)
    site_arg="${site:-<site>}"
    echo "DocType JSON edit detected — run \`bench --site $site_arg migrate\` before testing."
    ;;
  */hooks.py)
    site_arg="${site:-<site>}"
    echo "hooks.py edit detected — run \`bench --site $site_arg migrate && bench --site $site_arg clear-cache\` before testing."
    ;;
esac

exit 0
