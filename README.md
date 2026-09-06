# Agent Skills Pack: Homelab and VPS Ops

![tests](https://github.com/automate-it-all/agent-skills-pack/actions/workflows/tests.yml/badge.svg)

Ten AgentSkills-layout skills (`skills/<name>/SKILL.md` plus `references/`)
for running a home server or small VPS: reverse proxy, remote access,
hardening, bot deployment, backup, health checks. Four are free, under
`skills/`. Six are paid, plus `playbooks/`, under `paid/`, kept out of this
public repo by `.gitignore`.

Contact for the pack: skills@automate-it-all.win.

![Hermes running service-health-check](docs/skill-demo.gif)

Hermes reads `service-health-check`'s `SKILL.md` and runs its Step 1 script
unmodified, against a live loopback server.

## Free Skills

| skill | what it does |
|---|---|
| `vps-basics` | Locks down a fresh VPS or homelab box with ufw and fail2ban. |
| `backup-restore-drill` | Pairs every backup with a restore drill, so a backup counts only once it has been read back. |
| `service-health-check` | Checks process, port and HTTP layers in order, and restarts or alerts on the first that fails. |
| `systemd-unit-authoring` | Turns a script into a systemd service that restarts on crash and starts on boot. |

## Paid Skills: 19 EUR for 30 Days, Then 39 EUR

| skill | what it does |
|---|---|
| `caddy-reverse-proxy` | Reverse-proxies homelab services behind Caddy, private-subnet-only by default. |
| `tailscale-funnel` | Reaches a homelab box from anywhere over Tailscale's mesh or public edge, even behind CGNAT. |
| `pi-hardening` | Locks a headless Pi to key-only SSH and a scoped sudo allowlist from one whitelist file. |
| `telegram-bot-deployment` | Deploys a Telegram bot as a control channel, gated by a chat-ID allowlist. |
| `wan-failover-uplink-guard` | Fails a dual-homed box onto its backup uplink when the WAN dies but the link stays up. |
| `wol-wake-and-remote-shutdown` | Wakes a sleeping server over the LAN and shuts it back down, without holding a login on it. |

Buy the paid six from the store once it ships; this line gets the payment link.

## Layout

- `PROVENANCE.md` lists one line per source skill: verdict (`ship`,
  `anonymize` or `exclude`) and state (`todo` or `tested`).
- `skills/` holds the four free skills.
- `paid/skills/` holds the six paid skills.
- `paid/playbooks/` holds paid playbooks tying skills together.
- `tests/<name>.sh` runs one skill's own steps inside a fresh Docker
  container. `tests/run.sh` runs all of them.

## Agent Compatibility

| agent | status |
|---|---|
| Claude Code | Reads `SKILL.md` front matter natively; no extra loader needed. |
| Hermes | Ran `tests/run.sh` over the full ten-skill set before this pack shipped. |
| Any AgentSkills-spec loader | Reads the `skills/<name>/SKILL.md` layout; untested against a specific one. |

---

**Skills** · skills@automate-it-all.win · part of [Automate It All](https://automate-it-all.win) — [YouTube](https://www.youtube.com/@automateitallwin) · [Telegram](https://t.me/AutomateItAll) · [GitHub](https://github.com/automate-it-all) · [Reddit](https://www.reddit.com/user/AutomateItAllWin) · [X](https://x.com/automateallthin)
