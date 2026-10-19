import XCTest
import RealmSwift
import RxSwift
@testable import VSpace

final class FormCompletionViewModelTests: XCTestCase {

    private var db: KeepsakeDatabaseManager!
    private var disposeBag: DisposeBag!

    override func setUpWithError() throws {
        let config = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        db = KeepsakeDatabaseManager(configuration: config)
        disposeBag = DisposeBag()
    }

    func test_whenAvailable_secondaryTapGoesHomeAndPrimaryTapShowsRitual() throws {
        let keepsake = try makeKeepsake(disposalDate: Date().addingTimeInterval(-10))
        let sut = FormCompletionViewModel(keepsakeId: keepsake.id, db: db, storage: MediaStorageManager.shared)
        XCTAssertTrue(sut.isAvailable)

        let primaryTap = PublishSubject<Void>()
        let secondaryTap = PublishSubject<Void>()
        let output = sut.transform(input: .init(primaryTap: primaryTap, secondaryTap: secondaryTap))
        var goHomeCount = 0
        var showRitualCount = 0
        output.goHome.subscribe(onNext: { goHomeCount += 1 }).disposed(by: disposeBag)
        output.showRitual.subscribe(onNext: { showRitualCount += 1 }).disposed(by: disposeBag)

        secondaryTap.onNext(())
        primaryTap.onNext(())

        XCTAssertEqual(goHomeCount, 1)
        XCTAssertEqual(showRitualCount, 1)
    }

    func test_whenNotAvailable_primaryTapGoesHomeAndShowRitualNeverEmits() throws {
        let keepsake = try makeKeepsake(disposalDate: Date().addingTimeInterval(1000))
        let sut = FormCompletionViewModel(keepsakeId: keepsake.id, db: db, storage: MediaStorageManager.shared)
        XCTAssertFalse(sut.isAvailable)

        let primaryTap = PublishSubject<Void>()
        let secondaryTap = PublishSubject<Void>()
        let output = sut.transform(input: .init(primaryTap: primaryTap, secondaryTap: secondaryTap))
        var goHomeCount = 0
        var showRitualCount = 0
        output.goHome.subscribe(onNext: { goHomeCount += 1 }).disposed(by: disposeBag)
        output.showRitual.subscribe(onNext: { showRitualCount += 1 }).disposed(by: disposeBag)

        primaryTap.onNext(())
        secondaryTap.onNext(())

        XCTAssertEqual(goHomeCount, 1)
        XCTAssertEqual(showRitualCount, 0)
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
