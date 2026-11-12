import XCTest
import RealmSwift
import UIKit
@testable import VSpace

final class RitualCoordinatorTests: XCTestCase {

    private var db: KeepsakeDatabaseManager!
    private var mockAnalytics: MockAnalyticsTracker!

    override func setUpWithError() throws {
        let config = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        db = KeepsakeDatabaseManager(configuration: config)
        mockAnalytics = MockAnalyticsTracker()
    }

    func test_start_withStartAtRitualTrue_logsRitualStartedWithCreationSource() throws {
        let keepsake = try makeKeepsake()
        let sut = RitualCoordinator(
            navigationController: UINavigationController(),
            keepsakeId: keepsake.id,
            startAtRitual: true,
            db: db,
            analytics: mockAnalytics
        )

        sut.start()

        XCTAssertEqual(mockAnalytics.loggedEvents, [.ritualStarted(source: "creation")])
    }

    func test_showRitual_afterStartWithStartAtRitualFalse_logsRitualStartedWithStatusSource() throws {
        let keepsake = try makeKeepsake()
        let sut = RitualCoordinator(
            navigationController: UINavigationController(),
            keepsakeId: keepsake.id,
            startAtRitual: false,
            db: db,
            analytics: mockAnalytics
        )
        sut.start()

        sut.showRitual()

        XCTAssertEqual(mockAnalytics.loggedEvents, [.ritualStarted(source: "status")])
    }

    // MARK: - Fixtures

    @discardableResult
    private func makeKeepsake() throws -> Keepsake {
        let keepsake = Keepsake()
        keepsake.name = "기본값"
        keepsake.recordType = .photo
        keepsake.resourceFileName = "img_test.png"
        keepsake.thumbnailFileName = "thumb_test.png"
        keepsake.disposalDate = Date()
        keepsake.status = .unavailable
        try db.saveKeepsake(keepsake)
        return keepsake
    }
}
