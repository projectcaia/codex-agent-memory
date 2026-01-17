# Codex Backup (ProjectCaia / Caia local)

This repo is a **backup of Codex CLI configuration + helper scripts** used on this machine.

## What is safe to version-control
- `config.toml`, `profile.yaml`, `boot.md`
- `scripts/*.ps1`
- `AGENTS.template.md`, `recall_playbook.md`, `version.json`

## What must stay local-only
- Any secrets: `auth.json`, `internal_storage.json`, `.ssh/*`, `.env*`
- Runtime artifacts: `log/*`, `sessions/*`, `history.jsonl`, `memory/*`, `memory-repos/*`, `tmp/*`

## Notes
- The Caia “body/OS” lives at `C:\\Users\\A\\.caia-core` and is intentionally **not** stored inside `.codex`.
- Authority (shared memory) is external (`caia-memory-production`) and should not be backed up here.
