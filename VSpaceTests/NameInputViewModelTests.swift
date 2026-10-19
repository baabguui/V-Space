import XCTest
import RealmSwift
import RxSwift
@testable import VSpace

final class NameInputViewModelTests: XCTestCase {

    private var db: KeepsakeDatabaseManager!
    private var disposeBag: DisposeBag!

    override func setUpWithError() throws {
        let config = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        db = KeepsakeDatabaseManager(configuration: config)
        disposeBag = DisposeBag()
    }

    func test_isNextEnabled_whenNameIsWhitespaceOnly_isFalse() throws {
        let keepsake = try makeKeepsake()
        let sut = NameInputViewModel(keepsakeId: keepsake.id, db: db, storage: MediaStorageManager.shared)
        let nameSubject = PublishSubject<String>()
        let output = sut.transform(input: .init(name: nameSubject, nextTap: .empty()))
        var results: [Bool] = []
        output.isNextEnabled.subscribe(onNext: { results.append($0) }).disposed(by: disposeBag)

        nameSubject.onNext("   ")

        XCTAssertEqual(results, [false])
    }

    func test_isNextEnabled_whenNameHasActualCharacters_isTrue() throws {
        let keepsake = try makeKeepsake()
        let sut = NameInputViewModel(keepsakeId: keepsake.id, db: db, storage: MediaStorageManager.shared)
        let nameSubject = PublishSubject<String>()
        let output = sut.transform(input: .init(name: nameSubject, nextTap: .empty()))
        var results: [Bool] = []
        output.isNextEnabled.subscribe(onNext: { results.append($0) }).disposed(by: disposeBag)

        nameSubject.onNext("  철수  ")

        XCTAssertEqual(results, [true])
    }

    func test_nextTap_savesNameAndBumpsProgressStepTo2() throws {
        let keepsake = try makeKeepsake()
        let sut = NameInputViewModel(keepsakeId: keepsake.id, db: db, storage: MediaStorageManager.shared)
        let nameSubject = PublishSubject<String>()
        let nextTapSubject = PublishSubject<Void>()
        let output = sut.transform(input: .init(name: nameSubject, nextTap: nextTapSubject))
        var navigatedIds: [ObjectId] = []
        output.navigateNext.subscribe(onNext: { navigatedIds.append($0) }).disposed(by: disposeBag)

        nameSubject.onNext("철수")
        nextTapSubject.onNext(())

        XCTAssertEqual(navigatedIds, [keepsake.id])
        let saved = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertEqual(saved.name, "철수")
        XCTAssertEqual(saved.progressStep, 2)
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
