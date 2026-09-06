# Skill Provenance

One line per source skill or pattern. Columns: source, verdict
(`ship`/`anonymize`/`exclude`), state (`todo`/`tested`), note.

## New (No Source, Written From Scratch)

| skill | verdict | state | note |
|---|---|---|---|
| vps-basics | ship | tested | ufw + fail2ban baseline, no source skill covers this |
| backup-restore-drill | ship | tested | restore-tested backup drill, no source skill covers this |
| service-health-check | ship | tested | health-check pattern, no source skill covers this |
| systemd-unit-authoring | ship | tested | unit-file authoring, no source skill covers this |

## From server-bot-and-auto-shutdown (Paid)

| skill | source path | verdict | state | note |
|---|---|---|---|---|
| caddy-reverse-proxy | raspberry_pi/services/caddy/, raspberry_pi/services/check_caddy.sh | anonymize | tested | strip real domains/emails from Caddyfile |
| tailscale-funnel | ansible/roles/pi_server/tasks/06_docker_stack.yml, ansible/group_vars/all/vars.yml, raspberry_pi/services/caddy/config/Caddyfile | anonymize | tested | serve vs funnel, no auth key held so the test checks CLI flags, not a live tailnet |
| pi-hardening | ansible/roles/pi_server/templates/sudoers_pi.j2, ansible/roles/common/tasks/main.yml (authorized_key whitelist) | anonymize | tested | key-only SSH plus a scoped NOPASSWD allowlist, no real IPs/hosts in the skill |
| telegram-bot-deployment | raspberry_pi/services/webhooks_and_serverbot/ | anonymize | tested | strip bot tokens, chat IDs, /home/pi paths |
| wol-wake-and-remote-shutdown | serverbot_commands.py (trigger_lan_command), ansible/roles/plex_server/templates/sudoers_shutdown.j2, raspberry_pi/services/lan_runner.py.j2 | anonymize | tested | strip MAC address, static LAN IP; test stubs etherwake/ssh, asserts backup runs before shutdown |
| wan-failover-uplink-guard | ansible/roles/pi_server/templates/uplink-guard.sh.j2 | anonymize | tested | metric-race pattern kept, generic eth0/wlan0/gateway names, test drives the four-state machine with stubbed ip/ping/curl |

## From ~/.hermes/skills/ (Excluded)

| skill | verdict | state | note |
|---|---|---|---|
| devops/webhook-subscriptions | exclude | tested | Hermes webhook-platform API, no standalone equivalent outside Hermes |
| devops/sdlc-review | exclude | tested | Kanban-handoff review, not a hosting/ops skill |
| every remaining ~/.hermes/skills/* folder (apple, creative, crew-*, data-science, diagramming, director, domain, email, feeds, gaming, gifs, github, inference-sh, jira-ticket, magallanes*, mcp, media, mlops, mymanus, notebook-tree, note-taking, openhands, ponytail*, pr-comment, pr-made-by-ai-stats, productivity, prompt-*, red-teaming, research, retro, skill-creator, smart-home, social-media, software-development, specs, status, web, written-artifacts) | exclude | tested | out of domain: none teach VPS/homelab hosting, checked by name and folder purpose against the pack's subject |

## Verdict Counts

- ship: 4, anonymize: 6, exclude: 2 individually-checked + 1 bulk line (~40 folders)
- todo: 0, tested: 13 (the 2 exclude rows, the bulk exclude line, vps-basics,
  backup-restore-drill, service-health-check, systemd-unit-authoring,
  caddy-reverse-proxy, tailscale-funnel, pi-hardening, telegram-bot-deployment,
  wol-wake-and-remote-shutdown, wan-failover-uplink-guard)
