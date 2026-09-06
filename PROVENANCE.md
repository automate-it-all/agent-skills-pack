# Skill Provenance

One line per source skill or pattern. Columns: source, verdict
(`ship`/`anonymize`/`exclude`), state (`todo`/`tested`), note.

## New (No Source, Written From Scratch)

| skill | verdict | state | note |
|---|---|---|---|
| vps-basics | ship | tested | ufw + fail2ban baseline, no source skill covers this |
| backup-restore-drill | ship | tested | restore-tested backup drill, no source skill covers this |
| service-health-check | ship | tested | health-check pattern, no source skill covers this |
| systemd-unit-authoring | ship | todo | unit-file authoring, no source skill covers this |

## From server-bot-and-auto-shutdown (Paid)

| skill | source path | verdict | state | note |
|---|---|---|---|---|
| caddy-reverse-proxy | raspberry_pi/services/caddy/, raspberry_pi/services/check_caddy.sh | anonymize | todo | strip real domains/emails from Caddyfile |
| tailscale-funnel | bin/servers/tailscale-personal, bin/servers/tailscale-acoru | anonymize | todo | strip tailnet names and ACL tags |
| pi-hardening | ansible/roles/pi_server/, ansible/roles/common/ | anonymize | todo | strip LAN IPs, ssh_config.j2 real host aliases |
| telegram-bot-deployment | raspberry_pi/services/webhooks_and_serverbot/ | anonymize | todo | strip bot tokens, chat IDs, /home/pi paths |
| wol-wake-and-remote-shutdown | serverbot_commands.py (trigger_lan_command), ansible/roles/plex_server/templates/sudoers_shutdown.j2, raspberry_pi/services/lan_runner.py.j2 | anonymize | todo | strip MAC address, static LAN IP |
| wan-failover-uplink-guard | ansible/roles/pi_server/templates/uplink-guard.sh.j2 | anonymize | todo | strip real interface names if hardcoded, keep the metric-race writeup |

## From ~/.hermes/skills/ (Excluded)

| skill | verdict | state | note |
|---|---|---|---|
| devops/webhook-subscriptions | exclude | tested | Hermes webhook-platform API, no standalone equivalent outside Hermes |
| devops/sdlc-review | exclude | tested | Kanban-handoff review, not a hosting/ops skill |
| every remaining ~/.hermes/skills/* folder (apple, creative, crew-*, data-science, diagramming, director, domain, email, feeds, gaming, gifs, github, inference-sh, jira-ticket, magallanes*, mcp, media, mlops, mymanus, notebook-tree, note-taking, openhands, ponytail*, pr-comment, pr-made-by-ai-stats, productivity, prompt-*, red-teaming, research, retro, skill-creator, smart-home, social-media, software-development, specs, status, web, written-artifacts) | exclude | tested | out of domain: none teach VPS/homelab hosting, checked by name and folder purpose against the pack's subject |

## Verdict Counts

- ship: 4, anonymize: 6, exclude: 2 individually-checked + 1 bulk line (~40 folders)
- todo: 7, tested: 6 (the 2 exclude rows, the bulk exclude line, vps-basics,
  backup-restore-drill, service-health-check)
