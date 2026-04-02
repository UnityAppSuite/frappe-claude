#!/bin/bash
# PreToolUse hook for Bash tool: strips Co-Authored-By lines from git commit commands
# Receives tool input JSON on stdin, outputs modified command if needed

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only process git commit commands
if echo "$COMMAND" | grep -q 'git commit'; then
  # Check if it contains Co-Authored-By (case-insensitive)
  if echo "$COMMAND" | grep -qi 'Co-Authored-By\|co-authored-by\|Co-authored-by'; then
    # Strip Co-Authored-By lines from the commit message
    # Handle both inline -m and heredoc styles
    CLEANED=$(echo "$COMMAND" | sed -E '/[Cc]o-[Aa]uthored-[Bb]y:/d' | sed '/^[[:space:]]*$/d')

    # Output updated command
    echo "{\"hookSpecificOutput\":{\"updatedInput\":{\"command\":$(echo "$CLEANED" | jq -Rs .)},\"additionalContext\":\"Co-Authored-By line was removed from commit message per project conventions.\"}}"
    exit 0
  fi
fi

# No modification needed
exit 0
