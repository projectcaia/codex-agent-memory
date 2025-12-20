# codex-agent-memory

Source-of-truth for Codex agent long-term memory.

## Safety
- Never store secrets: tokens, API keys, private keys, credentials, session cookies.
- Never store personal sensitive data.

## Files
- `ltm/long_term_memory.jsonl`: long-term memory entries (one JSON object per line; must include `id`).
- `decisions/`: larger decision notes (markdown).
