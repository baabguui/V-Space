import XCTest
import RealmSwift
import UIKit
@testable import VSpace

/// 레지스트리: 삭제 시 파일+DB+알림 3자 동기화 (TESTING.md)
/// Keepsake 삭제 경로 4곳(KeepsakeStatusViewModel, KeepsakeFormCoordinator,
/// DisposalDateEditCoordinator, KeepsakeDetailCoordinator) 모두에서
/// `NotificationScheduling.cancelDisposalNotification`이 올바른 id로 호출되는지
/// mock으로 검증한다(실제 UNUserNotificationCenter는 사용하지 않음).
final class KeepsakeDeletionNotificationCancelTests: XCTestCase {

    private var db: KeepsakeDatabaseManager!
    private var mockScheduler: MockNotificationScheduler!

    override func setUpWithError() throws {
        let config = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        db = KeepsakeDatabaseManager(configuration: config)
        mockScheduler = MockNotificationScheduler()
    }

    func test_keepsakeStatusViewModel_deleteKeepsake_cancelsScheduledNotification() throws {
        let keepsakeId = try makeKeepsake().id
        let sut = KeepsakeStatusViewModel(
            keepsakeId: keepsakeId,
            db: db,
            storage: MediaStorageManager.shared,
            notificationScheduler: mockScheduler
        )

        sut.deleteKeepsake()

        XCTAssertEqual(mockScheduler.cancelledKeepsakeIds, [keepsakeId])
    }

    func test_keepsakeFormCoordinator_deleteKeepsake_cancelsScheduledNotification() throws {
        let keepsakeId = try makeKeepsake().id
        let sut = KeepsakeFormCoordinator(
            navigationController: UINavigationController(),
            keepsakeId: keepsakeId,
            db: db,
            storage: MediaStorageManager.shared,
            notificationScheduler: mockScheduler
        )

        sut.deleteKeepsake()

        XCTAssertEqual(mockScheduler.cancelledKeepsakeIds, [keepsakeId])
    }

    func test_disposalDateEditCoordinator_deleteKeepsake_cancelsScheduledNotification() throws {
        let keepsakeId = try makeKeepsake().id
        let sut = DisposalDateEditCoordinator(
            navigationController: UINavigationController(),
            keepsakeId: keepsakeId,
            db: db,
            storage: MediaStorageManager.shared,
            notificationScheduler: mockScheduler
        )

        sut.deleteKeepsake()

        XCTAssertEqual(mockScheduler.cancelledKeepsakeIds, [keepsakeId])
    }

    func test_keepsakeDetailCoordinator_deleteAndFinish_cancelsScheduledNotification() throws {
        let keepsakeId = try makeKeepsake().id
        let sut = KeepsakeDetailCoordinator(
            navigationController: UINavigationController(),
            keepsakeId: keepsakeId,
            db: db,
            mode: .readOnly,
            notificationScheduler: mockScheduler
        )

        sut.deleteAndFinish()

        XCTAssertEqual(mockScheduler.cancelledKeepsakeIds, [keepsakeId])
    }

    // MARK: - Fixtures

    @discardableResult
    private func makeKeepsake() throws -> Keepsake {
        let keepsake = Keepsake()
        keepsake.name = "기본값"
        keepsake.recordType = .photo
        keepsake.resourceFileName = "img_test.png"
        keepsake.thumbnailFileName = "thumb_test.png"
        keepsake.disposalDate = Date().addingTimeInterval(86_400 * 30)
        try db.saveKeepsake(keepsake)
        return keepsake
    }
}
