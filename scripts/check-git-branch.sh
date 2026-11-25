#!/usr/bin/env bash
# check-git-branch.sh — PreToolUse hook for Claude Code
#
# Blocks git add, git commit, and git push when:
#   1. The current branch is main
#   2. The branch name does not follow intent/|spec/|plan/ convention
#   3. (git commit only) The -m subject line exceeds 72 characters
#
# Exit 0 = allow  |  Exit 2 = block (message shown to Claude)
#
# JSON parsing uses python3; no dependency on jq.

# Store hook input JSON from stdin
INPUT=$(cat)
TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT
printf '%s' "$INPUT" > "$TMPFILE"

# Extract the command string; allow through on any parse failure
COMMAND=$(python3 -c 'import sys,json; d=json.load(open(sys.argv[1])); print(d.get("command",""))' "$TMPFILE" 2>/dev/null) || COMMAND=""

# Only gate git add / commit / push — everything else passes immediately
case "$COMMAND" in
  "git add"*|"git commit"*|"git push"*) ;;
  *) exit 0 ;;
esac

# Read current branch; allow through if git is unavailable
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0

# --- Check 1: block all three commands on main ---
if [[ "$BRANCH" == "main" ]]; then
  echo "Hook blocked: you are on branch 'main'." >&2
  echo "" >&2
  echo "Create a branch before staging, committing, or pushing:" >&2
  echo "  git checkout -b intent/<kebab-name>" >&2
  echo "  git checkout -b spec/<kebab-name>" >&2
  echo "  git checkout -b plan/<kebab-name>" >&2
  exit 2
fi

# --- Check 2: enforce branch naming convention ---
if [[ ! "$BRANCH" =~ ^(intent|spec|plan)/[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Hook blocked: branch '$BRANCH' does not follow the naming convention." >&2
  echo "" >&2
  echo "Rename your branch to match one of:" >&2
  echo "  intent/<kebab-name>  |  spec/<kebab-name>  |  plan/<kebab-name>" >&2
  exit 2
fi

# --- Check 3: commit subject line must be <= 72 characters (git commit only) ---
case "$COMMAND" in
  "git commit"*)
    # Write the Python helper to a temp file to avoid heredoc-in-subshell
    # parsing issues with triple-quoted strings.
    PYFILE=$(mktemp)
    trap "rm -f $TMPFILE $PYFILE" EXIT
    cat > "$PYFILE" << 'PYEOF'
import sys, json, re
try:
    d = json.load(open(sys.argv[1]))
    cmd = d.get("command", "")
    # Match -m "..." or -m '...' — capture group 2 is the message body
    m = re.search(r"""-m\s+(['"])(.*?)\1""", cmd, re.DOTALL)
    if m:
        subject = m.group(2).split('\n')[0]
        print(len(subject))
    else:
        print(0)
except Exception:
    print(0)
PYEOF

    SUBJECT_LEN=$(python3 "$PYFILE" "$TMPFILE" 2>/dev/null) || SUBJECT_LEN=0

    if (( SUBJECT_LEN > 72 )); then
      echo "Hook blocked: commit subject line is $SUBJECT_LEN characters (limit is 72)." >&2
      echo "Shorten the first line of the -m message and retry." >&2
      exit 2
    fi
    ;;
esac

exit 0
