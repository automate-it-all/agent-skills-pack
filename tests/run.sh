#!/usr/bin/env bash
# Runs every tests/<name>.sh here. Skips a skill whose SKILL.md says
# `host-specific: true`. Exits 0 only when nothing else fails.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

pass=0 fail=0 skip=0
for t in ./*.sh; do
  [ "$(basename "$t")" = "run.sh" ] && continue
  name="$(basename "$t" .sh)"
  skill_md=$(find ../skills ../paid/skills -maxdepth 2 -name SKILL.md -path "*/$name/*" 2>/dev/null | head -1)
  if [ -n "$skill_md" ] && grep -q '^host-specific: true' "$skill_md"; then
    echo "SKIP  $name (host-specific)"
    skip=$((skip + 1))
    continue
  fi
  if bash "$t"; then
    echo "PASS  $name"
    pass=$((pass + 1))
  else
    echo "FAIL  $name"
    fail=$((fail + 1))
  fi
done

echo "---"
echo "pass=$pass fail=$fail skip=$skip"
[ "$fail" -eq 0 ]
