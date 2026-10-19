import XCTest
import RealmSwift
import RxSwift
@testable import VSpace

final class KeepsakeStatusViewModelTests: XCTestCase {

    private var db: KeepsakeDatabaseManager!
    private var disposeBag: DisposeBag!

    override func setUpWithError() throws {
        let config = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        db = KeepsakeDatabaseManager(configuration: config)
        disposeBag = DisposeBag()
    }

    func test_primaryTap_whenNotAvailable_updatesDisposalDateToToday() throws {
        let futureDisposalDate = Date().addingTimeInterval(1000)
        let keepsake = try makeKeepsake(disposalDate: futureDisposalDate)
        let sut = KeepsakeStatusViewModel(keepsakeId: keepsake.id, db: db, storage: MediaStorageManager.shared)
        XCTAssertFalse(sut.isAvailable)

        let primaryTap = PublishSubject<Void>()
        let output = sut.transform(input: .init(primaryTap: primaryTap, secondaryTap: .empty()))
        output.showRitual.subscribe().disposed(by: disposeBag)

        primaryTap.onNext(())

        let updated = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertLessThan(abs(updated.disposalDate.timeIntervalSinceNow), 2)
    }

    func test_primaryTap_whenNotAvailable_cancelsNotificationForKeepsakeId() throws {
        let futureDisposalDate = Date().addingTimeInterval(1000)
        let keepsake = try makeKeepsake(disposalDate: futureDisposalDate)
        let mockScheduler = MockNotificationScheduler()
        let sut = KeepsakeStatusViewModel(
            keepsakeId: keepsake.id,
            db: db,
            storage: MediaStorageManager.shared,
            notificationScheduler: mockScheduler
        )
        XCTAssertFalse(sut.isAvailable)

        let primaryTap = PublishSubject<Void>()
        let output = sut.transform(input: .init(primaryTap: primaryTap, secondaryTap: .empty()))
        output.showRitual.subscribe().disposed(by: disposeBag)

        primaryTap.onNext(())

        XCTAssertEqual(mockScheduler.cancelledKeepsakeIds, [keepsake.id])
    }

    func test_primaryTap_whenAlreadyAvailable_doesNotChangeDisposalDate() throws {
        let pastDisposalDate = Date().addingTimeInterval(-1000)
        let keepsake = try makeKeepsake(disposalDate: pastDisposalDate)
        let sut = KeepsakeStatusViewModel(keepsakeId: keepsake.id, db: db, storage: MediaStorageManager.shared)
        XCTAssertTrue(sut.isAvailable)

        let primaryTap = PublishSubject<Void>()
        let output = sut.transform(input: .init(primaryTap: primaryTap, secondaryTap: .empty()))
        output.showRitual.subscribe().disposed(by: disposeBag)

        primaryTap.onNext(())

        let updated = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertEqual(updated.disposalDate.timeIntervalSinceReferenceDate, pastDisposalDate.timeIntervalSinceReferenceDate, accuracy: 0.001)
    }

    func test_primaryTap_whenAlreadyAvailable_doesNotCancelNotification() throws {
        let pastDisposalDate = Date().addingTimeInterval(-1000)
        let keepsake = try makeKeepsake(disposalDate: pastDisposalDate)
        let mockScheduler = MockNotificationScheduler()
        let sut = KeepsakeStatusViewModel(
            keepsakeId: keepsake.id,
            db: db,
            storage: MediaStorageManager.shared,
            notificationScheduler: mockScheduler
        )
        XCTAssertTrue(sut.isAvailable)

        let primaryTap = PublishSubject<Void>()
        let output = sut.transform(input: .init(primaryTap: primaryTap, secondaryTap: .empty()))
        output.showRitual.subscribe().disposed(by: disposeBag)

        primaryTap.onNext(())

        XCTAssertTrue(mockScheduler.cancelledKeepsakeIds.isEmpty)
    }

    @discardableResult
    private func makeKeepsake(disposalDate: Date) throws -> Keepsake {
        let keepsake = Keepsake()
        keepsake.name = "기본값"
        keepsake.recordType = .photo
        keepsake.resourceFileName = "img_test.png"
        keepsake.thumbnailFileName = "thumb_test.png"
        keepsake.disposalDate = disposalDate
        try db.saveKeepsake(keepsake)
        return keepsake
    }
}
