#!/usr/bin/env bash
# Follows service-health-check/SKILL.md in a fresh container: starts a toy
# HTTP service, asserts the check passes, kills it, asserts the check fails.
set -uo pipefail
skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/skills/service-health-check"

docker run --rm \
  -v "$skill_dir/references:/refs:ro" \
  ubuntu:22.04 bash -c '
    set -e
    apt-get update -qq && apt-get install -y -qq curl python3 procps >/dev/null
    mkdir -p /srv/www && echo ok > /srv/www/health
    (cd /srv/www && python3 -m http.server 8080 >/tmp/server.log 2>&1 &)
    sleep 1
    bash /refs/health-check.sh "http.server" 127.0.0.1 8080 http://127.0.0.1:8080/health | tee /tmp/out
    grep -q "^OK:" /tmp/out
    pkill -f "http.server"
    sleep 1
    if bash /refs/health-check.sh "http.server" 127.0.0.1 8080 http://127.0.0.1:8080/health; then
      echo "expected failure, got success" >&2
      exit 1
    fi
  '
