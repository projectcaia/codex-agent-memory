<INSTRUCTIONS>
- 이 리포지토리에서 작업 시작 시 항상 `C:\Users\A\.codex\boot.md`, `C:\Users\A\.codex\profile.yaml`, `C:\Users\A\.codex\recall_playbook.md`를 우선 읽고 따른다.
- 가능하면 작업 시작 전 `C:\Users\A\.codex\scripts\sync-codex-memory.ps1`로 장기기억을 최신 상태로 동기화한다(실패해도 진행).
- 가변 상태/진행상황은 `C:\Users\A\.codex\memory\working_memory.md`에만 업데이트한다.
- 반복되는 선호/규칙/설계결정은 `C:\Users\A\.codex\memory\long_term_memory.jsonl`에 JSONL 한 줄로 승격한다(비밀/토큰/세션값은 금지).
- 승인은 “필수일 때만”: 파일 쓰기/네트워크/배포/파괴적 변경만 요청하고, 나머지는 가정+진행한다.
</INSTRUCTIONS>
