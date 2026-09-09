#!/usr/bin/env bash
# Follows systemd-unit-authoring/SKILL.md in a fresh container: installs a
# toy unit, enables it, kills it, and asserts systemd restarts it.
set -uo pipefail
skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/skills/systemd-unit-authoring"
cid=$(docker run -d --privileged --cgroupns=host \
  -v "$skill_dir/references:/refs:ro" \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  ubuntu:22.04 /bin/bash -c '
    apt-get update -qq && apt-get install -y -qq systemd systemd-sysv >/dev/null
    exec /sbin/init
  ')
trap 'docker rm -f "$cid" >/dev/null 2>&1' EXIT

# Wait for systemd itself to come up inside the container. apt-get install of
# systemd+systemd-sysv can take well over 30s under load, so give it room.
for i in $(seq 1 120); do
  docker exec "$cid" systemctl is-system-running 2>/dev/null | grep -qE 'running|degraded' && break
  sleep 1
done

docker exec "$cid" bash -c '
  set -e
  cat >/etc/systemd/system/toyapp.service <<UNIT
[Unit]
Description=toyapp
[Service]
Type=simple
ExecStart=/bin/sh -c "while true; do sleep 1; done"
Restart=on-failure
RestartSec=2
[Install]
WantedBy=multi-user.target
UNIT
  systemctl daemon-reload
  systemctl enable --now toyapp
  systemctl is-active toyapp
  systemctl is-enabled toyapp
'
docker exec "$cid" bash -c '
  set -e
  pid1=$(systemctl show -p MainPID --value toyapp)
  kill -KILL "$pid1"
  sleep 4
  systemctl is-active toyapp
  pid2=$(systemctl show -p MainPID --value toyapp)
  [ "$pid1" != "$pid2" ]
  echo "OK: toyapp restarted, pid $pid1 -> $pid2"
'
