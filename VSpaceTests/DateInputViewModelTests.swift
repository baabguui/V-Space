import XCTest
import RealmSwift
import RxSwift
@testable import VSpace

final class DateInputViewModelTests: XCTestCase {

    private var db: KeepsakeDatabaseManager!
    private var disposeBag: DisposeBag!

    override func setUpWithError() throws {
        let config = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        db = KeepsakeDatabaseManager(configuration: config)
        disposeBag = DisposeBag()
    }

    func test_acquiredDate_withFullDate_savesDateAndBumpsProgressStepTo3() throws {
        let keepsake = try makeKeepsake()
        let sut = DateInputViewModel(keepsakeId: keepsake.id, config: .acquiredDate, db: db, storage: MediaStorageManager.shared)
        let partial = PartialDate(year: 2020, month: 3, day: 15)

        try save(sut: sut, partial: partial)

        let saved = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertEqual(saved.acquiredDate, Calendar.current.date(from: DateComponents(year: 2020, month: 3, day: 15)))
        XCTAssertEqual(saved.progressStep, 3)
        XCTAssertEqual(saved.acquiredYear, 2020)
        XCTAssertEqual(saved.acquiredMonth, 3)
        XCTAssertEqual(saved.acquiredDay, 15)
    }

    func test_acquiredDate_withPartialDate_leavesDateNilButStoresBreakdown() throws {
        let keepsake = try makeKeepsake()
        let sut = DateInputViewModel(keepsakeId: keepsake.id, config: .acquiredDate, db: db, storage: MediaStorageManager.shared)
        let partial = PartialDate(year: 2020, month: 3, day: 0)

        try save(sut: sut, partial: partial)

        let saved = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertNil(saved.acquiredDate)
        XCTAssertEqual(saved.progressStep, 3)
        XCTAssertEqual(saved.acquiredYear, 2020)
        XCTAssertEqual(saved.acquiredMonth, 3)
        XCTAssertEqual(saved.acquiredDay, 0)
    }

    func test_disposalDate_withFullDate_savesDateAndBumpsProgressStepTo4() throws {
        let keepsake = try makeKeepsake()
        let sut = DateInputViewModel(keepsakeId: keepsake.id, config: .disposalDate, db: db, storage: MediaStorageManager.shared)
        let partial = PartialDate(year: 2030, month: 1, day: 1)

        try save(sut: sut, partial: partial)

        let saved = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertEqual(saved.disposalDate, Calendar.current.date(from: DateComponents(year: 2030, month: 1, day: 1)))
        XCTAssertEqual(saved.progressStep, 4)
        XCTAssertEqual(saved.disposalYear, 2030)
        XCTAssertEqual(saved.disposalMonth, 1)
        XCTAssertEqual(saved.disposalDay, 1)
    }

    func test_disposalDate_withPartialDate_fallsBackToDistantFuture() throws {
        let keepsake = try makeKeepsake()
        let sut = DateInputViewModel(keepsakeId: keepsake.id, config: .disposalDate, db: db, storage: MediaStorageManager.shared)
        let partial = PartialDate(year: 0, month: 0, day: 0)

        try save(sut: sut, partial: partial)

        let saved = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertEqual(saved.disposalDate, .distantFuture)
        XCTAssertEqual(saved.progressStep, 4)
        XCTAssertEqual(saved.disposalYear, 0)
        XCTAssertEqual(saved.disposalMonth, 0)
        XCTAssertEqual(saved.disposalDay, 0)
    }

    private func save(sut: DateInputViewModel, partial: PartialDate) throws {
        let dateSubject = PublishSubject<PartialDate>()
        let nextTapSubject = PublishSubject<Void>()
        let output = sut.transform(input: .init(date: dateSubject, nextTap: nextTapSubject))
        output.navigateNext.subscribe().disposed(by: disposeBag)

        dateSubject.onNext(partial)
        nextTapSubject.onNext(())
    }

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
