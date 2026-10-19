import XCTest
import RealmSwift
import UIKit
@testable import VSpace

final class KeepsakeDetailCoordinatorTests: XCTestCase {

    private var db: KeepsakeDatabaseManager!

    override func setUpWithError() throws {
        let config = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        db = KeepsakeDatabaseManager(configuration: config)
    }

    // MARK: - finish() : .completion (unavailable → done 전환)

    func test_finish_completionMode_withNoRitualDate_setsStatusDoneAndFillsRitualDateWithNow() throws {
        let keepsake = try makeKeepsake()
        let sut = KeepsakeDetailCoordinator(
            navigationController: UINavigationController(),
            keepsakeId: keepsake.id,
            db: db,
            mode: .completion
        )

        sut.finish()

        let updated = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertEqual(updated.status, .done)
        let ritualDate = try XCTUnwrap(updated.ritualDate)
        XCTAssertLessThan(abs(ritualDate.timeIntervalSinceNow), 2)
    }

    func test_finish_completionMode_withExistingRitualDate_doesNotOverwriteIt() throws {
        let keepsake = try makeKeepsake()
        let existingRitualDate = Date().addingTimeInterval(-10_000)
        try db.updateKeepsake(keepsake) { $0.ritualDate = existingRitualDate }
        let sut = KeepsakeDetailCoordinator(
            navigationController: UINavigationController(),
            keepsakeId: keepsake.id,
            db: db,
            mode: .completion
        )

        sut.finish()

        let updated = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertEqual(updated.status, .done)
        let ritualDate = try XCTUnwrap(updated.ritualDate)
        XCTAssertEqual(ritualDate.timeIntervalSinceReferenceDate, existingRitualDate.timeIntervalSinceReferenceDate, accuracy: 0.001)
    }

    func test_finish_completionMode_callsOnFinish() throws {
        let keepsake = try makeKeepsake()
        let sut = KeepsakeDetailCoordinator(
            navigationController: UINavigationController(),
            keepsakeId: keepsake.id,
            db: db,
            mode: .completion
        )
        var onFinishCalled = false
        sut.onFinish = { onFinishCalled = true }

        sut.finish()

        XCTAssertTrue(onFinishCalled)
    }

    // MARK: - finish() : .readOnly (DB 변경 없음)

    func test_finish_readOnlyMode_doesNotChangeStatusOrRitualDate() throws {
        let keepsake = try makeKeepsake()
        let sut = KeepsakeDetailCoordinator(
            navigationController: UINavigationController(),
            keepsakeId: keepsake.id,
            db: db,
            mode: .readOnly
        )

        sut.finish()

        let updated = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertEqual(updated.status, .unavailable)
        XCTAssertNil(updated.ritualDate)
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
