import XCTest
import RealmSwift
import UIKit
@testable import VSpace

final class PlaneCaptureCoordinatorTests: XCTestCase {

    private var db: KeepsakeDatabaseManager!
    private var mockAnalytics: MockAnalyticsTracker!

    override func setUpWithError() throws {
        let config = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        db = KeepsakeDatabaseManager(configuration: config)
        mockAnalytics = MockAnalyticsTracker()
    }

    // `pendingKeepsakeId`는 이미지 피커(UI) 플로우를 통해서만 채워지는 private 상태라
    // "사진 확정 후 완료"(로그가 찍히는 경로)는 유닛테스트로 재현할 수 없다. 여기서는
    // 사진을 선택하지 않고 완료를 누른 경우(guard 미충족) 로그가 찍히지 않는 것만 검증한다.
    func test_finishCapture_withoutPendingKeepsake_doesNotLog() {
        let sut = PlaneCaptureCoordinator(
            navigationController: UINavigationController(),
            db: db,
            storage: MediaStorageManager.shared,
            analytics: mockAnalytics
        )

        sut.finishCapture()

        XCTAssertEqual(mockAnalytics.loggedEvents, [])
    }
}
