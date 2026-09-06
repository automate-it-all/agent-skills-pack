---
name: systemd-unit-authoring
description: Turn a script or long-running process into a systemd service that restarts on crash and starts on boot.
version: 0.1.0
author: agent-skills-pack
license: MIT
platforms: [linux]
---

# Systemd Unit Authoring

## Overview

A script started by hand from a terminal dies the moment that terminal
closes, and a script started from `rc.local` never restarts after it
crashes. A systemd unit fixes both: `systemctl enable` survives a reboot,
and `Restart=on-failure` survives a crash. This skill writes one unit file,
installs it, and proves both properties before calling the job done.

## Steps

1. Copy `references/app.service` to `/etc/systemd/system/<name>.service`
   and fill in `ExecStart` (a full path, never a bare command name: systemd
   runs with a minimal `PATH`), `User`, and `WorkingDirectory`.
2. `Restart=on-failure` with `RestartSec=5` restarts a crashed process
   after a 5-second backoff. Without a `RestartSec`, a process that dies
   in a crash loop restarts hundreds of times a minute and floods the
   journal.
3. `systemctl daemon-reload` after every edit to the unit file: systemd
   caches unit files at daemon start and after each `daemon-reload`, so an
   edit with no reload runs the old unit.
4. `systemctl enable --now <name>` starts the service now and links it
   into the boot target. `enable` alone only links it; `--now` also starts
   it, so a fresh unit that was `enable`d but not started reads as
   "installed" while doing nothing until the next reboot.
5. `journalctl -u <name> -n 50` reads the unit's own log. A unit with no
   `StandardOutput`/`StandardError` override sends both to the journal
   already, so a fresh `println`-style script needs no extra logging setup
   to become inspectable.

## Verification

- `systemctl is-active <name>` prints `active` right after `enable --now`.
- `systemctl kill -s KILL <name>` kills the process; `systemctl is-active
  <name>` prints `activating` or `active` again within `RestartSec` plus a
  few seconds, proving the crash-restart property.
- `systemctl is-enabled <name>` prints `enabled`, proving the unit survives
  a reboot without a fresh `enable` call.

## Troubleshooting

- `systemctl start <name>` reports success but `is-active` reads `failed`
  seconds later: the process exited immediately after systemd marked it
  started. Read `journalctl -u <name> -n 50` for the process's own exit
  reason before touching the unit file again.
- `ExecStart=myscript.sh` fails with "No such file or directory" even
  though the script runs fine by hand: systemd does not read the calling
  shell's `PATH` or `cwd`. Use an absolute path for `ExecStart` and set
  `WorkingDirectory` explicitly.
- A `Restart=on-failure` unit that keeps flapping every `RestartSec`
  forever: after `StartLimitBurst` restarts inside `StartLimitIntervalSec`,
  systemd stops trying and the unit sits `failed`. Fix the root cause the
  journal names, then `systemctl reset-failed <name>` before starting
  again; a `daemon-reload` alone does not clear that counter.
- Editing the unit file directly under `/etc/systemd/system/` and
  forgetting `daemon-reload`: `systemctl restart <name>` runs the
  in-memory old unit, not the file on disk, so a change appears to do
  nothing.
