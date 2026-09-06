#!/usr/bin/env bash
# Follows tailscale-funnel/SKILL.md steps 1-3, syntax-only: no tailnet auth key.
#
# Checks the CLI still accepts the flags the skill documents. A flag rename
# or removal upstream fails this test and flags the skill as stale.
set -uo pipefail

docker run --rm tailscale/tailscale:latest sh -c '
    set -e
    up=$(tailscale up --help 2>&1)
    echo "$up" | grep -q -- "--auth-key" || { echo "FAIL: tailscale up lost --auth-key"; exit 1; }
    echo "$up" | grep -q -- "--hostname" || { echo "FAIL: tailscale up lost --hostname"; exit 1; }
    echo "$up" | grep -q -- "--accept-routes" || { echo "FAIL: tailscale up lost --accept-routes"; exit 1; }

    serve=$(tailscale serve --help 2>&1)
    echo "$serve" | grep -q -- "--bg" || { echo "FAIL: tailscale serve lost --bg"; exit 1; }
    echo "$serve" | grep -q -- "--https" || { echo "FAIL: tailscale serve lost --https"; exit 1; }

    funnel=$(tailscale funnel --help 2>&1)
    echo "$funnel" | grep -q -- "--bg" || { echo "FAIL: tailscale funnel lost --bg"; exit 1; }
    echo "$funnel" | grep -qi "internet" || { echo "FAIL: tailscale funnel help no longer describes public exposure"; exit 1; }
    echo "$serve" | grep -qi "tailnet" || { echo "FAIL: tailscale serve help no longer describes tailnet-only sharing"; exit 1; }

    echo "OK: tailscale up/serve/funnel still accept the flags the skill documents"
'
