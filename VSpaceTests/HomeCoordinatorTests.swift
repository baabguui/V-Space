import XCTest
import RealmSwift
import UIKit
@testable import VSpace

final class HomeCoordinatorTests: XCTestCase {

    private var mockAnalytics: MockAnalyticsTracker!
    private var db: KeepsakeDatabaseManager!
    private var savedKeepsakeIds: [ObjectId] = []

    override func setUpWithError() throws {
        mockAnalytics = MockAnalyticsTracker()
        db = KeepsakeDatabaseManager()
    }

    override func tearDownWithError() throws {
        for id in savedKeepsakeIds {
            if let keepsake = db.fetchKeepsake(id: id) {
                try db.deleteKeepsake(keepsake)
            }
        }
        savedKeepsakeIds = []
    }

    func test_showKeepsakeDetail_withDoneKeepsake_logsCompletedKeepsakeRevisited() throws {
        let keepsake = try makeSavedKeepsake(status: .done)
        let sut = HomeCoordinator(navigationController: UINavigationController(), analytics: mockAnalytics)

        sut.showKeepsakeDetail(keepsake: keepsake)

        XCTAssertEqual(mockAnalytics.loggedEvents, [.completedKeepsakeRevisited])
    }

    func test_showKeepsakeDetail_withNonDoneKeepsake_doesNotLog() throws {
        let keepsake = try makeSavedKeepsake(status: .unavailable)
        let sut = HomeCoordinator(navigationController: UINavigationController(), analytics: mockAnalytics)

        sut.showKeepsakeDetail(keepsake: keepsake)

        XCTAssertEqual(mockAnalytics.loggedEvents, [])
    }

    // MARK: - Fixtures

    /// `HomeCoordinator.showKeepsakeDetail`는 내부적으로 기본 설정 Realm을 쓰는
    /// `KeepsakeDetailCoordinator`를 생성해 `.start()`까지 호출하므로, 실제로 DB에
    /// 저장된 Keepsake여야 한다(프로덕션에서도 홈에 보이는 keepsake는 항상 DB에 존재).
    private func makeSavedKeepsake(status: FuneralStatus) throws -> Keepsake {
        let keepsake = Keepsake()
        keepsake.name = "기본값"
        keepsake.recordType = .photo
        keepsake.resourceFileName = "img_test.png"
        keepsake.thumbnailFileName = "thumb_test.png"
        keepsake.disposalDate = Date()
        keepsake.status = status
        try db.saveKeepsake(keepsake)
        savedKeepsakeIds.append(keepsake.id)
        return keepsake
    }
}
