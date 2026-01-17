# LTM JSONL Schema (Human Spec)

`ltm/long_term_memory.jsonl` is **JSON Lines**: one JSON object per line.

## Required
- `id` (string): stable unique identifier (e.g. `LTM-YYYYMMDD-0001`)
- `summary` (string): short, high-signal statement

## Strongly recommended
- `ts` (string, ISO-8601): when this memory was created/updated
- `type` (string): `preference` | `rule` | `decision` | `pattern` | `lesson`
- `topic` (array of strings): tags for retrieval
- `priority` (number 1..5): 5 = most important
- `triggers` (array of strings): when to recall (e.g. `new_session`, `before_major_decision`)

## Optional
- `details` (object): structured details, rationale, examples
- `status` (string): `active` | `deprecated`
- `links` (object/array): references (e.g. decision note paths)

## Example
```json
{"id":"LTM-20251220-0004","ts":"2025-12-20T23:00:00+09:00","type":"rule","topic":["workflow","safety"],"summary":"Never persist secrets to memory repos; block sync if patterns match.","details":{"deny":["tokens","private keys","passwords"]},"triggers":["any_write_to_memory_repo"],"priority":5,"status":"active"}
```
