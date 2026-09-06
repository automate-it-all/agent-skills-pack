#!/usr/bin/env bash
# Follows skills/telegram-bot-deployment/SKILL.md in a fresh container:
# runs references/webhook_verify.py's self-check (allowlist plus HMAC),
# and proves the start.sh supervisor exits when either child process does.
set -uo pipefail
skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/paid/skills/telegram-bot-deployment"

docker run --rm \
  -v "$skill_dir/references:/refs:ro" \
  python:3.10-alpine sh -c '
    set -e
    apk add --no-cache bash coreutils >/dev/null
    python /refs/webhook_verify.py

    mkdir -p /tmp/run && cd /tmp/run
    cat > bot.py <<EOF
import time
time.sleep(0.2)
raise SystemExit(1)
EOF
    cat > webhook_listener.py <<EOF
import time
time.sleep(30)
EOF
    cp /refs/start.sh .
    set +e
    timeout 5 bash start.sh
    code=$?
    set -e
    [ "$code" -ne 0 ] || { echo "supervisor exited 0, expected nonzero from bot.py"; exit 1; }
    [ "$code" -ne 124 ] || { echo "supervisor did not exit when bot.py did (timed out)"; exit 1; }
    echo "OK: supervisor exits with the first child, does not wait on the other"
  '
