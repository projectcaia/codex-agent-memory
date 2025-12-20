# codex-agent-memory

Git-backed long-term memory store for the Codex agent helping Donghyun.

## Quickstart
- Sync (merge local ↔ repo, then push if changed): `powershell -ExecutionPolicy Bypass -File scripts/sync.ps1`

If you’re running from anywhere, use the global wrapper:
- `powershell -ExecutionPolicy Bypass -File C:\Users\A\.codex\scripts\sync-codex-memory.ps1`

## Layout
- `ltm/long_term_memory.jsonl`: canonical long-term memory (JSONL; unique `id` per line)
- `decisions/`: longer decision notes (markdown), referenced from LTM when needed
- `views/`: optional generated summaries for browsing
- `scripts/`: sync/validate/render helpers

## Specs
- Policy: `POLICY.md`
- JSONL format: `SCHEMA.md`

## Safety (non-negotiable)
- Never store secrets: tokens, API keys, private keys, passwords, cookies, session IDs.
- Never store sensitive personal data.
