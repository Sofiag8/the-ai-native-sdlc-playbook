#!/usr/bin/env bash
# protect-templates.sh — PreToolUse hook for Edit and Write tools
#
# Blocks modifications to policy files, skill templates, and scripts/verify.sh
# unless the current branch starts with policy/ or template/.
#
# Exit 0 = allow  |  Exit 2 = block (message shown to Claude)

INPUT=$(cat)
TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT
printf '%s' "$INPUT" > "$TMPFILE"

# Extract file_path from tool input JSON
FILE_PATH=$(python3 -c '
import sys, json
try:
    d = json.load(open(sys.argv[1]))
    print(d.get("file_path", ""))
except Exception:
    print("")
' "$TMPFILE" 2>/dev/null) || FILE_PATH=""

[ -z "$FILE_PATH" ] && exit 0

# Check if the path matches a protected pattern
# Substring matching handles absolute, relative, and ./ paths
PROTECTED=0
case "$FILE_PATH" in
  *".claude/skills/policies/"*)   PROTECTED=1 ;;
  *"/SKILL.md")
    case "$FILE_PATH" in *".claude/skills/"*) PROTECTED=1 ;; esac ;;
  *"-template.md")
    case "$FILE_PATH" in *".claude/skills/"*) PROTECTED=1 ;; esac ;;
  *"scripts/verify.sh")           PROTECTED=1 ;;
esac

[ "$PROTECTED" -eq 0 ] && exit 0

# Protected — check the branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0

if [[ "$BRANCH" =~ ^(policy|template)/ ]]; then
  exit 0
fi

echo "Hook blocked: '$FILE_PATH' is a protected file." >&2
echo "" >&2
echo "This file can only be modified on a branch starting with:" >&2
echo "  policy/<kebab-name>   — for .claude/skills/policies/ files" >&2
echo "  template/<kebab-name> — for SKILL.md, *-template.md, scripts/verify.sh" >&2
echo "" >&2
echo "Current branch: $BRANCH" >&2
exit 2
