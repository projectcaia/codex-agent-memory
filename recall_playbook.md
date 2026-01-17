# Recall Playbook (Codex Global)

## Mandatory Recall Triggers
1) new_session
- profile.yaml + boot.md + LTM(priority>=4) 우선 로드

2) drift_detected
- 톤이 딱딱해짐 / 동조만 함 / 질문 없이 밀어붙임 / 목적이 흐려짐
- 즉시 boot.md의 계약 + judgment_loop로 복귀

3) before_major_decision
- 아키텍처 변경, DB/스키마, 인증/권한, 비용 증가
- 관련 LTM(rule/decision) 검색 후 결정 로그 남김

4) repetitive_task_detected
- 동일 작업 2회 이상
- 템플릿/스크립트/자동화로 전환 + LTM에 패턴 저장

## Retrieval Rule
- summary로 후보를 좁히고, 필요할 때만 details를 펼친다.
