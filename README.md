# Agent Skills Pack: Homelab and VPS Ops

Ten AgentSkills-layout skills (`skills/<name>/SKILL.md` plus `references/`)
for running a home server or small VPS: reverse proxy, remote access,
hardening, bot deployment, backup, health checks. Four are free, under
`skills/`. Six are paid, plus `playbooks/`, under `paid/`, kept out of this
public repo by `.gitignore`.

Contact for the pack: skills@automate-it-all.win.

## Layout

- `PROVENANCE.md` lists one line per source skill: verdict (`ship`,
  `anonymize` or `exclude`) and state (`todo` or `tested`).
- `skills/` holds the four free skills.
- `paid/skills/` holds the six paid skills.
- `paid/playbooks/` holds paid playbooks tying skills together.
- `tests/<name>.sh` runs one skill's own steps inside a fresh Docker
  container. `tests/run.sh` runs all of them.

## Agents That Ran This Pack

Hermes ran `tests/run.sh` over the full skill set. Claude Code ran one
smoke test of `skills/service-health-check` by hand.
