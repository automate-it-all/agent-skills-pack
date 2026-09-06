#!/usr/bin/env bash
# Follows backup-restore-drill/SKILL.md in a fresh container: creates data,
# backs up, restores, and asserts a clean diff.
set -uo pipefail
skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/skills/backup-restore-drill"

docker run --rm \
  -v "$skill_dir/references:/refs:ro" \
  ubuntu:22.04 bash -c '
    set -e
    mkdir -p /data/app && echo "hello world" > /data/app/file.txt
    bash /refs/backup.sh /data/app /archives /restore | tee /tmp/out
    grep -q "OK: .* restores byte-identical to /data/app" /tmp/out
  '
