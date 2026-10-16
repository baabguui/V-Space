# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

Xcode 프로젝트로, CLI 빌드 명령은 없습니다. Xcode에서 직접 빌드하거나 아래 명령을 사용합니다:

```bash
xcodebuild -project VSpace.xcodeproj -scheme VSpace -sdk iphonesimulator build
```

테스트 타겟은 현재 없습니다.

## 작업 원칙

### 변경 원칙
- 기존 아키텍처와 코딩 컨벤션을 우선적으로 따릅니다.
- 요청된 작업과 무관한 코드는 변경하지 않습니다.
- 새로운 추상화나 외부 의존성을 도입하기 전에 기존 구현을 확인합니다.
- 명시적인 요청 없이 대규모 리팩터링을 수행하지 않습니다.
- 기존 데이터 모델과 저장 구조의 하위 호환성을 유지합니다. Realm 모델 필드를 추가·삭제·타입 변경할 때는 `RealmMigrationManager`에 마이그레이션 로직을 추가하고 스키마 버전을 올립니다.

### 구현 전 확인
- 변경 대상 코드와 호출 관계를 먼저 파악합니다.
- 기존에 동일하거나 유사한 기능이 구현되어 있는지 확인합니다.
- 변경으로 영향을 받을 수 있는 기능과 도메인 규칙을 파악합니다. 특히 Keepsake 생성·삭제·수정 시 DB·파일(`MediaStorageManager`)·알림(`NotificationScheduler`) 세 저장소가 함께 동기화되는지 확인합니다.
- 요구사항이 불명확하거나 데이터 손실 위험이 있는 경우 임의로 판단하지 않고 확인을 요청합니다.

### 검증
- 코드 변경 후 가능한 범위에서 빌드를 실행합니다.
- 테스트가 존재하는 경우 관련 테스트를 실행합니다.
- UI 변경 시 가능한 범위에서 시뮬레이터로 실제 동작을 확인합니다.
- 빌드 및 테스트 실패 시 원인을 분석하고 해결합니다.
- 검증하지 못한 항목은 성공한 것으로 보고하지 않습니다.
- 테스트 통과를 위해 기존 테스트를 임의로 삭제하거나 검증 조건을 완화하지 않습니다.

### 작업 완료 보고
- 변경한 내용과 이유를 요약합니다.
- 빌드 및 테스트 결과를 명시합니다.
- 확인하지 못한 사항이나 남은 위험을 보고합니다.
- 명시적인 요청 없이 Git Commit 또는 Push를 실행하지 않습니다.

## Architecture

**패턴 규칙**:
- MVVM + Coordinator 패턴을 유지합니다.
- ViewController는 UI 구성과 사용자 입력을 담당하며, `BaseViewController`를 상속해 `disposeBag`과 `showAlert()` 헬퍼를 공유합니다.
- ViewModel은 비즈니스 로직과 RxSwift 스트림을 담당합니다.
- Coordinator는 화면 전환과 자식 Coordinator 생명주기를 관리합니다.
- Coordinator 간 의존성은 Protocol로 주입합니다.
- 새로운 화면은 기존 VC/VM/Coordinator 구조를 따릅니다.

**코디네이터 계층**:
```
AppCoordinator
└── HomeCoordinator (HomeCoordinating)
    ├── PlaneCaptureCoordinator  → KeepsakeFormCoordinator
    ├── ObjectCaptureCoordinator → KeepsakeFormCoordinator
    │   └── KeepsakeFormCoordinator
    │       └── RitualCoordinator (startAtRitual: true)
    ├── RitualCoordinator (KeepsakeStatus → Ritual → KeepsakeDetail)
    │   └── DisposalDateEditCoordinator (KeepsakeStatus에서 보내주는 날 재설정, KeepsakeFormCoordinating 재사용)
    └── KeepsakeDetailCoordinator
```

의존성 주입은 `CoordinatorProtocols.swift`의 프로토콜을 통해 이뤄집니다. 부모 코디네이터는 `onFinish` 클로저를 통해 자식 완료를 처리하고 `removeChildCoordinator(_:)`로 메모리를 해제합니다.

**데이터 흐름**:
- **DB**: `KeepsakeDatabaseManager` (Realm) → `KeepsakeDatabaseManaging` 프로토콜로 주입
  - 예외: `AppCoordinator.handleNotificationTap`은 `KeepsakeDatabaseManager()`를 직접 생성(미주입)
- **파일**: `MediaStorageManager.shared` → `MediaStorageManaging` 프로토콜로 주입
- **임시 파일**: `CaptureStorageManager` — ObjectCapture 세션마다 새 인스턴스 생성, 이전 세션 잔여 파일은 초기화 시 일괄 삭제
- **알림**: `NotificationScheduler` — disposalDate 기준 로컬 알림 스케줄/취소. Keepsake 삭제/날짜 변경 시 각 ViewModel/Coordinator가 수동으로 schedule/cancel을 호출해야 하며, DB·파일 삭제와 자동 동기화되지 않음(삭제 경로마다 취소 호출 누락 여부를 개별 확인 필요)

**Realm 주의사항**:
- `HomeViewModel`은 `results.observe`로 Realm 변경을 감지하며, UI에 전달하는 객체는 `.freeze()`된 상태입니다.
- `RealmMigrationManager.configure()`는 `AppDelegate`에서 호출됩니다.
- 현재 스키마 버전: **1** (최초 배포 버전)

**캡처 타입**:
- `PlaneCapture`: 사진 촬영 → 원형 크롭 → PHOTO 타입 Keepsake
- `ObjectCapture`: RealityKit `ObjectCaptureSession`으로 USDZ 생성 → THREE_D 타입 Keepsake (iOS 17+, `ObjectCaptureSession.isSupported` 체크 필수)

**Keepsake 상태 머신**:
```
inProgress → (Form 완성) → unavailable → (의례 실행) → done
```
`FuneralStatus`에는 `available` case가 정의돼 있지만 실제로 저장되는 값이 아닙니다(코드 내 어디서도 할당되지 않는 미사용 case). "지금 의례 가능한가"는 저장된 상태가 아니라 `isAvailable`(`disposalDate <= Date()`) 계산 프로퍼티로 매 조회 시 판별합니다.

**PartialDate**: 날짜 일부가 미상인 경우를 처리하는 값 타입. year/month/day 중 0인 필드가 미상을 의미합니다. Realm에는 `acquiredYear/Month/Day`, `disposalYear/Month/Day` 필드로 별도 저장합니다.
- 이와 별개로 `acquiredDate`/`disposalDate`(구체적 `Date`)도 함께 저장됩니다. Y/M/D breakdown은 "일부 미상" 표시용이고, Date 필드는 `isAvailable` 계산·정렬 등 비즈니스 로직용으로 병행 유지되는 것이며 레거시 마이그레이션 잔재가 아닙니다.

## 파일 저장 구조

```
Documents/
├── Captures/{uuid}/         ← 임시 (CaptureStorageManager, 세션 후 자동 정리)
├── .Objects/Models/         ← obj_{uuid}.usdz
├── .Objects/Images/         ← img_{uuid}.png
├── .Thumbnails/             ← thumb_{uuid}.png
└── .Certs/                  ← 의례 결과 (예정)
```

## 의존성

| 패키지 | 용도 |
|--------|------|
| RxSwift / RxCocoa / RxRelay | 반응형 바인딩 |
| SnapKit | 오토레이아웃 |
| RealmSwift | 로컬 DB |

## 커밋 컨벤션

### 메시지 형식
`<type>: <한국어 설명>` 형식을 따릅니다 (`git log` 기준 관찰된 타입):
- `feat`: 새 기능 추가
- `fix`: 버그 수정
- `refactor`: 동작 변경 없는 구조 개선
- `test`: 테스트 코드/하네스 추가·수정
- `chore`: 빌드/설정/에셋/버전 등 코드 로직 외 변경
- `ci`: CI/CD 워크플로우 변경

설명은 "무엇을 왜" 바꿨는지 한국어로 간결하게 적습니다.

### 작업 중 발견한 self-inflicted 버그
**지금 하고 있는 작업 자체가 원인이 되어** 새로 만든 버그를 구현 중에 발견해 바로 고친 경우, 별도의 `fix:` 커밋으로 분리하지 않고 현재 작업 커밋에 합칩니다. 아직 배포되지 않은 변경에 대한 수정이라 별도 히스토리로 추적할 가치가 없습니다.
- 반대로 **이미 배포된 코드에 있던 기존 버그**를 고치는 경우는 이 규칙에 해당하지 않습니다 — 별도의 `fix:` 커밋으로 분리합니다.
- 작업과 무관한 영역에서 우연히 발견한 기존 버그는 고치지 않고 보고만 합니다(변경 원칙 참고).

# 코드 스타일 가이드

## 주석 금지사항
- **WHAT 설명 금지**: 코드가 "무엇을" 하는지 설명하는 주석을 쓰지 않습니다. 네이밍으로 이미 명확한 내용을 반복하지 않습니다. WHY(숨은 제약, 특이한 workaround, non-obvious한 이유)만 주석으로 남깁니다.
- **죽은 코드 주석 금지**: 주석 처리된(`//`) 코드 블록을 남기지 않습니다. 불필요한 코드는 완전히 삭제하고, 필요하면 git 히스토리로 복구합니다.
- **TODO/FIXME 금지**: 이슈 번호와 작성일이 없는 `TODO`/`FIXME`는 남기지 않습니다. 추적 안 되는 TODO는 배포된 앱에서 영구히 방치될 위험이 있습니다.
- **민감정보 금지**: API 키, 실제 사용자 데이터 예시, 테스트 계정 정보 등을 주석에 적지 않습니다.
