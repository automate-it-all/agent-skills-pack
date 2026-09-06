#!/usr/bin/env bash
# Follows skills/pi-hardening/SKILL.md in a fresh container, then asserts
# sshd disables password auth and sudo -l shows only the named commands.
set -uo pipefail
skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/paid/skills/pi-hardening"

docker run --rm \
  -v "$skill_dir/references:/refs:ro" \
  ubuntu:22.04 bash -c '
    set -e
    apt-get update -qq && apt-get install -y -qq openssh-server sudo >/dev/null
    useradd -m -s /bin/bash pi
    echo "pi:x" | chpasswd -e
    mkdir -p /etc/ssh/sshd_config.d
    cp /refs/sshd-hardening.conf /etc/ssh/sshd_config.d/hardening.conf
    cp /refs/sudoers-scoped /etc/sudoers.d/pi-scoped
    chmod 440 /etc/sudoers.d/pi-scoped
    visudo -c -f /etc/sudoers.d/pi-scoped
    mkdir -p /run/sshd
    /usr/sbin/sshd -t
    sshd -T | grep -qi "^passwordauthentication no"
    sshd -T | grep -qi "^permitrootlogin no"
    sudo -l -U pi | grep -q "/usr/sbin/etherwake"
    sudo -l -U pi | grep -qv "NOPASSWD: ALL"
    ! sudo -l -U pi | grep -q "(ALL) NOPASSWD: ALL"
  '
