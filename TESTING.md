# TESTING.md

이 문서는 `test-writer`/`reviewer` 서브에이전트가 "어떤 테스트가 필요한가"를 판단하는 기준입니다. coder/test-writer/reviewer/tester 파이프라인(`.claude/workflows/dev-pipeline.js`)에서 참조합니다.

## 유닛테스트 판단 기준

다음 세 가지를 모두 만족할수록 유닛테스트 작성 가치가 높습니다.

1. **버그 비용이 높은가** — 조용히 실패했을 때 사용자 데이터(사진/3D 모델/DB 레코드)가 유실되거나 깨지는 영역인가.
2. **로직이 순수하고 분기가 있는가** — 외부 의존(디스크/DB/UIKit) 없이 조건 분기가 있는 코드인가.
3. **격리 비용이 낮은가** — DI로 이미 분리돼 있어 목/임시 자원으로 갈아끼우기 쉬운가.

**쓰지 말아야 할 테스트** (trivial, 작성 금지):
- 네이밍만 다른 getter/setter
- Realm/UIKit 등 프레임워크 자체 동작을 재검증하는 테스트
- 이미 다른 테스트가 커버하는 경로의 단순 반복

## 통합테스트 판단 기준

아래 패턴에 해당하면 통합테스트 대상입니다:

> 여러 레이어(DB·FileSystem·Notification 등)에 걸쳐 있고, 실패 시 조용한 데이터 불일치·유실·고아 상태를 유발하는 지점

이 패턴은 실제로 한 번 터진 전례(ObjectCapture 임시 디렉토리 정리 누락, `e42806a`)가 있는 유형입니다.

## 통합테스트 레지스트리 (정적, 알려진 위험 지점)

| 항목 | 위치 | 왜 중요한가 |
|---|---|---|
| 삭제 시 파일+DB+알림 3자 동기화 | `KeepsakeStatusViewModel.deleteKeepsake`, `KeepsakeFormCoordinator.deleteKeepsake`, `DisposalDateEditCoordinator.deleteKeepsake` | 삭제 경로 3곳 중 알림 취소가 빠진 전례 발견. 세 경로가 같은 계약을 지키는지 회귀 방지 |
| ObjectCapture 취소/저장 후 임시 디렉토리 정리 | `CaptureViewModel.handleSessionState` + `CaptureStorageManager.cleanup` | 전례 있는 버그 영역(`e42806a`), 상태 기반 분기라 회귀 취약 |
| 재선택(reselect) 시 이전 Keepsake 정리 | `PlaneCaptureCoordinator.saveKeepsake` | 파일+DB 동시 정리가 깨지면 고아 파일/레코드 발생 |
| disposalDate 변경 시 알림 재스케줄 | `DisposalDateEditCoordinator.handleDisposalDateSaved` → `FormCompletionViewModel.scheduleNotification` | cancel과 schedule이 서로 다른 화면/클래스에 분산돼 있어 한쪽만 누락되기 쉬움 |
| 알림 탭 → 삭제된 Keepsake 처리 | `AppCoordinator.handleNotificationTap` | nil keepsake 처리가 보장되지 않으면 크래시 |

이 표는 작업 건수에 비례해 쌓이는 기록이 아니라, **지금 코드베이스에 실재하는 위험 지점의 지도**입니다. 위 패턴(여러 레이어 + 조용한 실패)에 해당하는 새 지점을 발견하면 행을 추가하고, 리팩터링 등으로 그 위험이 없어졌으면 행을 지우거나 고치세요. 대부분의 작업은 이 표를 건드리지 않습니다.

## 동적 위험 태깅 (coder → test-writer)

레지스트리는 "이미 알고 있는 위험"만 담습니다. 새로 작성되는 코드의 위험도는 작성한 사람이 가장 잘 압니다. 그래서 `coder` 서브에이전트는 작업 결과를 넘길 때 변경 사항별로 **왜 위험한지/왜 안전한지**를 한 줄씩 태깅합니다. `test-writer`는 (레지스트리 + 이 위험 태그 + diff)를 함께 보고 유닛/통합 테스트 범위를 결정합니다.

## 하네스 참고사항

- 테스트 타겟: `VSpaceTests` (XCTest, `IPHONEOS_DEPLOYMENT_TARGET = 18.6`로 앱 타겟과 맞춤)
- `KeepsakeDatabaseManager`는 `Realm.Configuration` 주입 가능 → 테스트에서 `Realm.Configuration(inMemoryIdentifier: UUID().uuidString)`로 격리
- `MediaStorageManager`는 `baseDirectory: URL` 주입 가능 → 테스트에서 임시 디렉토리로 격리
- 레퍼런스 예시: `VSpaceTests/MediaStorageManagerTests.swift`, `VSpaceTests/KeepsakeDatabaseManagerTests.swift`
