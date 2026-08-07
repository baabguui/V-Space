# <img width="40" alt="image" src="https://github.com/user-attachments/assets/46d96953-a902-4ff0-a92c-09a145c10fb7" /> V-Space

버리기 망설여지는 물건을 디지털로 기록하고, 현실 공간을 정리할 수 있도록 돕는 앱입니다.

`UIKit` `RealityKit` `RxSwift` `Realm` `FileManager`

- 개발 기간: 2026.03 (2주)
- 개인 프로젝트 · 2026년 3월 앱스토어 출시

## 스크린샷

<img width="160" alt="image" src="https://github.com/user-attachments/assets/81235cdd-5403-4f51-826f-e87d3f0cc30d" />
<img width="160" alt="image" src="https://github.com/user-attachments/assets/0afa992c-cc74-4e2d-bc33-cbdad1727c07" />
<img width="160" alt="image" src="https://github.com/user-attachments/assets/6effe4e3-fd48-4c96-9021-0118fecaa259" />
<img width="160" alt="image" src="https://github.com/user-attachments/assets/f0626e40-b5d2-498f-91b2-9dc7e04ce593" />
<img width="160" alt="image" src="https://github.com/user-attachments/assets/bf775b39-dbb1-4a94-8a90-8eb7a03a256d" />
<img width="160" alt="image" src="https://github.com/user-attachments/assets/fa98ca4a-415a-4f58-a3d8-4a04bc36d790" />


## 주요 기능

- 3D 스캔
- 사진 기반 물건 기록 저장
- 3D 모델·사진 미리보기
- 저장한 물건 목록 조회

## 기술적 특징

- **ObjectCaptureSession 유지 상태에서의 중간 3D 모델 생성**: 스캔 세션을 종료하지 않고 파일 접근만 멈춰 상태를 유지한 채 미리보기용 3D 모델(USDZ)을 생성하고, 세션 내부 비동기 파일 접근과의 충돌로 인한 크래시를 정리 시점 조정으로 방지
- **파일 저장 및 Realm 구독 범위 최적화**: 3D 모델·원본 이미지는 파일 시스템에, DB에는 경로만 저장. 홈 화면에 실제로 영향을 주는 필드로 Realm 구독 범위를 좁혀 불필요한 화면 갱신 차단
- **Coordinator 기반 화면 전환 구조**: 여러 단계로 나뉜 입력 폼의 진행 상태 저장·재개와 서로 다른 진입 경로의 합류를 Coordinator로 분리해 관리
- **GitHub Actions 기반 CI**: push·PR마다 iOS 시뮬레이터 빌드를 자동으로 검증
