#!/usr/bin/env bash
# Follows skills/vps-basics/SKILL.md inside a fresh privileged container,
# then asserts ufw is active with the named ports and the sshd jail is up.
set -uo pipefail
skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/skills/vps-basics"

docker run --rm --privileged \
  -v "$skill_dir/references:/refs:ro" \
  ubuntu:22.04 bash -c '
    set -e
    apt-get update -qq && apt-get install -y -qq ufw fail2ban >/dev/null
    ufw default deny incoming >/dev/null
    ufw default allow outgoing >/dev/null
    ufw allow 22/tcp >/dev/null
    ufw allow 80/tcp >/dev/null
    ufw allow 443/tcp >/dev/null
    ufw --force enable >/dev/null
    cp /refs/jail.local /etc/fail2ban/jail.local
    touch /var/log/auth.log
    service fail2ban start
    sleep 2
    ufw status | grep -q "Status: active"
    ufw status | grep -q "22/tcp"
    fail2ban-client status sshd | grep -q "Status for the jail: sshd"
  '
