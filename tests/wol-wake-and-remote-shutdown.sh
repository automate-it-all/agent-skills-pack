#!/usr/bin/env bash
# Follows skills/wol-wake-and-remote-shutdown/SKILL.md in a fresh container:
# stubs etherwake/sudo/ssh on PATH, feeds the dispatcher WAKE then
# SHUTDOWN_SEQUENCE, and asserts the call order and the trigger-file clear.
set -uo pipefail
skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/paid/skills/wol-wake-and-remote-shutdown"

docker run --rm \
  -v "$skill_dir/references:/refs:ro" \
  python:3.11-slim bash -c '
    set -e
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq && apt-get install -y -qq sudo >/dev/null
    visudo -c -f /refs/sudoers-wol
    visudo -c -f /refs/sudoers-shutdown
    grep -q "NOPASSWD: /usr/sbin/etherwake" /refs/sudoers-wol
    ! grep -q "NOPASSWD: ALL" /refs/sudoers-wol
    grep -q "NOPASSWD: /sbin/shutdown" /refs/sudoers-shutdown
    ! grep -q "NOPASSWD: ALL" /refs/sudoers-shutdown

    mkdir -p /stub /work
    log=/work/calls.log
    for bin in etherwake sudo ssh; do
      printf "#!/bin/sh\necho \"CALL $bin \$*\" >> %s\n" "$log" > "/stub/$bin"
      chmod +x "/stub/$bin"
    done
    export PATH=/stub:$PATH

    export TARGET_MAC=aa:bb:cc:dd:ee:ff TARGET_IP=203.0.113.10 TARGET_USER=example
    export BACKUP_CMD=/opt/backup.sh TRIGGER_FILE=/work/trigger

    echo WAKE > "$TRIGGER_FILE"
    python3 /refs/lan_runner.py.example
    grep -q "CALL sudo /usr/sbin/etherwake.*aa:bb:cc:dd:ee:ff" "$log"
    [ ! -s "$TRIGGER_FILE" ]

    : > "$log"
    echo SHUTDOWN_SEQUENCE > "$TRIGGER_FILE"
    python3 /refs/lan_runner.py.example
    grep -n "CALL ssh" "$log"
    first=$(grep -n "CALL ssh" "$log" | head -1 | cut -d: -f1)
    second=$(grep -n "CALL ssh" "$log" | tail -1 | cut -d: -f1)
    [ "$first" -lt "$second" ]
    sed -n "${first}p" "$log" | grep -q "/opt/backup.sh"
    sed -n "${second}p" "$log" | grep -q "sudo -n /sbin/shutdown now"
    [ ! -s "$TRIGGER_FILE" ]
  '
