#!/usr/bin/env bash
# verify.sh — document integrity checks for the AI-native SDLC playbook
#
# Check 1: every file in spec/ has a matching file in intent/
# Check 2: every file in plan/ has a matching file in spec/
# Check 3: all .claude/agents/*.md files have name: and description: frontmatter
# Check 4: CLAUDE.md is under 250 lines
#
# Exit 0 = all checks passed  |  Exit 1 = one or more checks failed

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0

pass() { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; FAILURES=$((FAILURES + 1)); }

echo "Running verification checks..."
echo ""

# --- Check 1: spec/ files have matching intent/ files ---
echo "Check 1: spec/ files have matching intent/ files"
for spec_file in "$REPO_ROOT"/spec/*.md; do
  [ -f "$spec_file" ] || continue
  base="$(basename "$spec_file")"
  if [ -f "$REPO_ROOT/intent/$base" ]; then
    pass "spec/$base  →  intent/$base"
  else
    fail "spec/$base  →  intent/$base NOT FOUND"
  fi
done
echo ""

# --- Check 2: plan/ files have matching spec/ files ---
echo "Check 2: plan/ files have matching spec/ files"
for plan_file in "$REPO_ROOT"/plan/*.md; do
  [ -f "$plan_file" ] || continue
  base="$(basename "$plan_file")"
  if [ -f "$REPO_ROOT/spec/$base" ]; then
    pass "plan/$base  →  spec/$base"
  else
    fail "plan/$base  →  spec/$base NOT FOUND"
  fi
done
echo ""

# --- Check 3: .claude/agents/*.md files have required frontmatter ---
echo "Check 3: .claude/agents/*.md files have name: and description: frontmatter"
agents_dir="$REPO_ROOT/.claude/agents"
if [ -d "$agents_dir" ]; then
  found=0
  for agent_file in "$agents_dir"/*.md; do
    [ -f "$agent_file" ] || continue
    found=$((found + 1))
    base="$(basename "$agent_file")"
    has_name=$(python3 -c "
import sys
content = open(sys.argv[1]).read()
in_front = False
for line in content.splitlines():
    if line.strip() == '---':
        if not in_front: in_front = True; continue
        else: break
    if in_front and line.startswith('name:'): print('yes'); sys.exit(0)
print('no')
" "$agent_file" 2>/dev/null)
    has_desc=$(python3 -c "
import sys
content = open(sys.argv[1]).read()
in_front = False
for line in content.splitlines():
    if line.strip() == '---':
        if not in_front: in_front = True; continue
        else: break
    if in_front and line.startswith('description:'): print('yes'); sys.exit(0)
print('no')
" "$agent_file" 2>/dev/null)
    if [ "$has_name" = "yes" ] && [ "$has_desc" = "yes" ]; then
      pass ".claude/agents/$base  →  name: and description: present"
    else
      [ "$has_name" != "yes" ] && fail ".claude/agents/$base  →  missing name:"
      [ "$has_desc" != "yes" ] && fail ".claude/agents/$base  →  missing description:"
    fi
  done
  [ "$found" -eq 0 ] && pass ".claude/agents/ exists but no .md files (nothing to check)"
else
  pass ".claude/agents/ does not exist yet (nothing to check)"
fi
echo ""

# --- Check 4: CLAUDE.md is under 250 lines ---
echo "Check 4: CLAUDE.md is under 250 lines"
claude_file="$REPO_ROOT/CLAUDE.md"
if [ -f "$claude_file" ]; then
  line_count=$(wc -l < "$claude_file")
  if [ "$line_count" -lt 250 ]; then
    pass "CLAUDE.md is $line_count lines (limit: 250)"
  else
    fail "CLAUDE.md is $line_count lines — exceeds 250-line limit"
  fi
else
  fail "CLAUDE.md not found"
fi
echo ""

# --- Summary ---
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
