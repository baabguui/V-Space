# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

Xcode 프로젝트로, CLI 빌드 명령은 없습니다. Xcode에서 직접 빌드하거나 아래 명령을 사용합니다:

```bash
xcodebuild -project VSpace.xcodeproj -scheme VSpace -sdk iphonesimulator build
```

테스트 타겟은 현재 없습니다.

## Architecture

**패턴**: MVVM + Coordinator

모든 화면은 `ViewController` / `ViewModel` / `Coordinator` 세 파일로 구성됩니다. 코디네이터가 화면 전환을 전담하며, ViewModel은 비즈니스 로직과 RxSwift 스트림을 담당합니다. ViewController는 `BaseViewController`를 상속하고 `disposeBag`과 `showAlert()` 헬퍼를 공유합니다.

**코디네이터 계층**:
```
AppCoordinator
└── HomeCoordinator (HomeCoordinating)
    ├── PlaneCaptureCoordinator  → KeepsakeFormCoordinator
    ├── ObjectCaptureCoordinator → KeepsakeFormCoordinator
    │   └── KeepsakeFormCoordinator
    │       └── RitualCoordinator (startAtRitual: true)
    ├── RitualCoordinator (KeepsakeStatus → Ritual → KeepsakeDetail)
    └── KeepsakeDetailCoordinator
```

코디네이터 간 의존성은 프로토콜(`CoordinatorProtocols.swift`)로 주입됩니다. 부모 코디네이터는 `onFinish` 클로저를 통해 자식 완료를 처리하고 `removeChildCoordinator(_:)`로 메모리를 해제합니다.

**데이터 흐름**:
- **DB**: `KeepsakeDatabaseManager` (Realm) → `KeepsakeDatabaseManaging` 프로토콜로 주입
- **파일**: `MediaStorageManager.shared` → `MediaStorageManaging` 프로토콜로 주입
- **임시 파일**: `CaptureStorageManager` — ObjectCapture 세션마다 새 인스턴스 생성, 이전 세션 잔여 파일은 초기화 시 일괄 삭제

**Realm 주의사항**:
- `HomeViewModel`은 `results.observe`로 Realm 변경을 감지하며, UI에 전달하는 객체는 `.freeze()`된 상태입니다.
- `RealmMigrationManager.configure()`는 `AppDelegate`에서 호출됩니다.
- 현재 스키마 버전: **1** (최초 배포 버전)

**캡처 타입**:
- `PlaneCapture`: 사진 촬영 → 원형 크롭 → PHOTO 타입 Keepsake
- `ObjectCapture`: RealityKit `ObjectCaptureSession`으로 USDZ 생성 → THREE_D 타입 Keepsake (iOS 17+, `ObjectCaptureSession.isSupported` 체크 필수)

**Keepsake 상태 머신**:
```
inProgress → (Form 완성) → available / unavailable → (의례 실행) → done
```
`available` 여부는 `disposalDate <= Date()`로 계산합니다(`isAvailable` 프로퍼티).

**PartialDate**: 날짜 일부가 미상인 경우를 처리하는 값 타입. year/month/day 중 0인 필드가 미상을 의미합니다. Realm에는 `acquiredYear/Month/Day`, `disposalYear/Month/Day` 필드로 별도 저장합니다.

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

# 코드 스타일 가이드

## 함수 주석
- 모든 함수 위에 `///`로 문서화 주석 작성 (여러 줄 가능)
- 함수의 역할, 파라미터, 반환값을 포함
- 예시 형식:
```swift
  /// 두 숫자의 합을 계산합니다
  /// - Parameters:
  ///   - a: 첫 번째 숫자
  ///   - b: 두 번째 숫자
  /// - Returns: a와 b의 합
  func add(a: Int, b: Int) -> Int {
    return a + b
  }
```

### 여러 줄 주석
긴 설명이 필요할 때는 여러 개의 `///`를 사용합니다:

```swift
/// API에서 사용자 데이터를 가져옵니다
/// 인증 처리 및 에러 핸들링을 포함합니다
/// 결과를 5분간 캐싱하여 API 호출을 줄입니다
/// - Parameters:
///   - userId: 사용자의 고유 식별자
/// - Throws: 요청이 실패하면 NetworkError 발생
/// - Returns: 사용자 데이터 객체
func getUser(userId: String) async throws -> User {
  // 구현
}
```
