---
name: service-health-check
description: Catch a dead or unresponsive service before a user reports it.
version: 0.1.0
author: agent-skills-pack
license: MIT
platforms: [linux]
---

# Service Health Check

## Overview

A service that crashes at 3am stays down until a user hits it and files a
complaint. This skill checks three layers in order: the process exists, the
port accepts a connection, and the application answers a real HTTP request.
A process check alone misses a hung process that still holds its port; a
port check alone misses an app that accepts connections but returns 500 on
every request. Run all three, and stop at the first that fails.

## Steps

1. Point `references/health-check.sh` at the service:

       references/health-check.sh <process-name> <host> <port> <health-url>

   Example: `references/health-check.sh nginx 127.0.0.1 80
   http://127.0.0.1/health`.
2. The script exits 0 and prints an `OK: ...` line when all three checks
   pass, or exits 1 and prints which check failed. Wire it into cron or a
   systemd timer on a short interval (1-5 minutes for anything user-facing).
3. Pipe a failing exit code into an alert, the same way
   `backup-restore-drill` does: `references/health-check.sh ... || mail -s
   "service down" ops@example.com`. A check that only logs to a file nobody
   reads is a check that never ran.
4. Give the application a real `/health` route rather than pointing the
   URL check at `/`: a route that queries its database or its own cache
   line catches "the app answers HTTP but its dependency is dead", which a
   bare `/` never would.

## Verification

- Run the script against a live service; it prints `OK: <name> up, <host>:
  <port> open, <url> returned 200`.
- Stop the service and rerun; the script exits 1 and names which of the
  three checks failed.

## Troubleshooting

- The process check passes but the port check fails right after a
  restart: the app is still binding. Add a short retry loop around the
  port check (`for i in 1 2 3; do check && break; sleep 2; done`) rather
  than treating a slow-starting service as down.
- `curl` returns `000` for the HTTP status: the URL is unreachable, not
  erroring. Check the port check ran first and passed; a `000` after a
  passing port check usually means the app expects a `Host` header
  (`curl -H "Host: real.example.com" ...`) or TLS (`https://` against a
  plain HTTP script) it never got.
- `pgrep -f <name>` matches the health-check script's own command line
  when `<name>` is a common word (like `check`): pick a process-name
  argument specific enough to miss the checker itself, or match a full
  path with `pgrep -f "/usr/bin/myservice"`.
- The health endpoint returns 200 even when a real dependency (database,
  queue) is down: the route only checks that the web process is alive.
  Have the route actually query the dependency and return non-2xx on
  failure, or this check gives a false OK during the outage that matters
  most.
