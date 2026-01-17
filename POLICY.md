# Codex Agent Memory Policy

This repository exists to persist **Codex long‑term memory** across machines/workspaces (via git) so the agent can continuously improve while helping Donghyun.

## What belongs here (LTM)
- Stable preferences (tone, output style, workflow defaults)
- Reusable rules (“always do X”, “never do Y”)
- Decisions + rationale (architecture choices, trade-offs, conventions)
- Patterns and playbooks (repeatable procedures, checklists, templates)
- High-signal lessons learned (postmortems, recurring pitfalls)

## What must NOT be stored here
- Any secret: tokens, API keys, private keys, passwords, cookies, session IDs
- Any sensitive personal data
- Ephemeral state: temporary logs, transient numbers, one-off task context

## Workflow (recommended)
1) Keep ephemeral details in local working memory only (`C:\Users\A\.codex\memory\working_memory.md`).
2) Promote only stable learnings into `ltm/long_term_memory.jsonl`.
3) When a “decision” needs more context, create a markdown note under `decisions/` and reference it from an LTM entry.
4) Sync frequently using `scripts/sync.ps1` (or the global wrapper `C:\Users\A\.codex\scripts\sync-codex-memory.ps1`).

## Enforcement
`scripts/sync.ps1` is expected to refuse pushing if it detects obvious secret patterns.
