---
name: dev-pipeline
description: 승인된 계획(plan)을 받아 coder -> test-writer -> reviewer -> tester 순서로 실행하고, reviewer나 tester가 실패하면 피드백과 함께 coder로 돌아가 최대 3회까지 반복합니다. VSpace 프로젝트의 커스텀 서브에이전트(.claude/agents/)를 사용합니다.
disable-model-invocation: true
---

아래 계획을 대상으로 코드 작성 -> 테스트 작성 -> 리뷰 -> 테스트 실행 파이프라인을 수행하세요.

계획:
$ARGUMENTS

## 절차

iteration을 1부터 시작해 최대 3까지 반복합니다. feedback은 처음엔 비어 있고, 이전 반복에서 reviewer가 거부하거나 tester가 실패하면 그 내용으로 채워집니다.

1. **Code** — `Agent` 도구로 `subagent_type: "coder"` 호출.
   - feedback이 없으면 프롬프트는 위 계획 그대로.
   - feedback이 있으면 "{계획}\n\n이전 시도에 대한 피드백입니다. 최소 범위로 수정하세요:\n{feedback}"로 구성.
   - 결과에서 변경 요약, 변경 파일 목록, 위험 태깅(riskNotes)을 받습니다.
   - 결과를 받지 못하면 즉시 중단하고 사용자에게 보고하세요.

2. **Write Tests** — `Agent` 도구로 `subagent_type: "test-writer"` 호출.
   - 프롬프트: coder의 요약, 변경 파일 목록, 위험 태깅을 전달하고 TESTING.md 기준으로 필요한 테스트만 작성하도록 요청.
   - 결과에서 테스트 파일 목록, 작성하지 않은 이유(skippedRationale)를 받습니다.
   - 결과를 받지 못하면 즉시 중단하고 사용자에게 보고하세요.

3. **Review** — `Agent` 도구로 `subagent_type: "reviewer"` 호출.
   - 프롬프트: coder 요약/변경파일/위험태깅 + test-writer 요약/테스트파일/미작성 사유를 전달하고 리뷰를 요청.
   - 거부(passed: false)되면 issues를 feedback으로 기록하고 iteration을 1 증가시켜 1번부터 재시도.
   - 결과를 받지 못하면 즉시 중단하고 사용자에게 보고하세요.

4. **Test** — reviewer가 통과시킨 경우에만 `Agent` 도구로 `subagent_type: "tester"` 호출.
   - 프롬프트: "방금 coder/test-writer가 작업 디렉토리에 반영한 변경 사항을 대상으로 VSpaceTests 전체를 실행하고 결과를 보고하세요."
   - 실패(passed: false)하면 failures를 feedback으로 기록하고 iteration을 1 증가시켜 1번부터 재시도.
   - 통과하면 아래 "완료 보고"로 진행.
   - 결과를 받지 못하면 즉시 중단하고 사용자에게 보고하세요.

## 완료 보고

통과 시: 반복 횟수, coder 요약, 변경 파일, 작성된 테스트 파일을 사용자에게 보고합니다.

3회 반복 후에도 통과하지 못하면 임의로 더 반복하지 말고, 마지막 feedback과 각 반복에서 무엇이 실패했는지를 사용자에게 보고하고 중단합니다.
