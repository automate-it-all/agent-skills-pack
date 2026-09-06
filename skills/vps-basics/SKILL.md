---
name: vps-basics
description: Lock down a fresh VPS or homelab box with ufw and fail2ban.
version: 0.1.0
author: agent-skills-pack
license: MIT
platforms: [linux]
---

# VPS Basics: ufw + fail2ban

## Overview

A fresh VPS ships with every port reachable and no brute-force protection.
This skill closes that gap in two steps: `ufw` denies inbound traffic by
default and allows only named ports, `fail2ban` bans an IP that fails SSH
login repeatedly. Do this before any service goes on the box, not after.

## Steps

1. Install both tools:

       apt-get update && apt-get install -y ufw fail2ban

2. Set the firewall's default policy, then open only the ports the box
   needs. Always open SSH before enabling, or the enable locks you out:

       ufw default deny incoming
       ufw default allow outgoing
       ufw allow 22/tcp
       ufw allow 80/tcp
       ufw allow 443/tcp
       ufw --force enable

3. Point fail2ban's SSH jail at the box's real log path and enable it.
   `references/jail.local` is the template; copy it in and adjust
   `logpath` if the distro's SSH log lives elsewhere (`/var/log/secure` on
   RHEL-family, `/var/log/auth.log` on Debian-family):

       cp references/jail.local /etc/fail2ban/jail.local
       systemctl enable --now fail2ban

## Verification

- `ufw status` shows `Status: active` and lists the allowed ports.
- `fail2ban-client status sshd` shows the jail running with 0 banned IPs.
- From a second host, `ssh` to a port `ufw` did not open times out rather
  than refusing, confirming the deny-by-default policy is live.

## Troubleshooting

- `ufw enable` over an SSH session with no port 22 rule yet drops that
  session mid-command. Add the SSH allow rule first, always.
- `fail2ban-client status sshd` answering `Sorry but the jail 'sshd' does
  not exist` means the jail name in `jail.local` does not match the
  distro's default (some ship `[sshd]` disabled by default; the template
  sets `enabled = true` explicitly).
- A systemd-only distro's SSH log goes to the journal, not a file. Set
  `backend = systemd` in `jail.local` instead of a `logpath` line.
- `ufw` silently no-ops inside an unprivileged container (no iptables
  access); this is a container-testing limitation, not a skill bug. Run
  `docker run --privileged` (or, on real hardware, plain root) for the
  firewall half; fail2ban's rule and jail parsing test fine unprivileged.
