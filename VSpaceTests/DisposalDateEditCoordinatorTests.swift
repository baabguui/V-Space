import XCTest
import RealmSwift
import UIKit
@testable import VSpace

final class DisposalDateEditCoordinatorTests: XCTestCase {

    private var db: KeepsakeDatabaseManager!

    override func setUpWithError() throws {
        let config = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        db = KeepsakeDatabaseManager(configuration: config)
    }

    // MARK: - handleDisposalDateSaved

    func test_handleDisposalDateSaved_cancelsNotificationForKeepsakeId() throws {
        let keepsake = try makeKeepsake()
        let mockScheduler = MockNotificationScheduler()
        let sut = DisposalDateEditCoordinator(
            navigationController: UINavigationController(),
            keepsakeId: keepsake.id,
            db: db,
            storage: MediaStorageManager.shared,
            notificationScheduler: mockScheduler
        )

        sut.handleDisposalDateSaved(keepsakeId: keepsake.id)

        XCTAssertEqual(mockScheduler.cancelledKeepsakeIds, [keepsake.id])
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
        try db.saveKeepsake(keepsake)
        return keepsake
    }
}
