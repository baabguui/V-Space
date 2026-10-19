import XCTest
import RealmSwift
import RxSwift
@testable import VSpace

final class TextInputViewModelTests: XCTestCase {

    private var db: KeepsakeDatabaseManager!
    private var disposeBag: DisposeBag!

    override func setUpWithError() throws {
        let config = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        db = KeepsakeDatabaseManager(configuration: config)
        disposeBag = DisposeBag()
    }

    func test_ability_whenWhitespaceOnly_normalizesToNil() throws {
        let keepsake = try makeKeepsake()
        let sut = TextInputViewModel(keepsakeId: keepsake.id, config: .ability, db: db, storage: MediaStorageManager.shared)

        try save(sut: sut, text: "   ")

        let saved = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertNil(saved.ability)
        XCTAssertEqual(saved.progressStep, 5)
    }

    func test_ability_withText_savesTextAndBumpsProgressStepTo5() throws {
        let keepsake = try makeKeepsake()
        let sut = TextInputViewModel(keepsakeId: keepsake.id, config: .ability, db: db, storage: MediaStorageManager.shared)

        try save(sut: sut, text: "날 수 있음")

        let saved = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertEqual(saved.ability, "날 수 있음")
        XCTAssertEqual(saved.progressStep, 5)
    }

    func test_memoryNote_whenWhitespaceOnly_normalizesToNil() throws {
        let keepsake = try makeKeepsake()
        let sut = TextInputViewModel(keepsakeId: keepsake.id, config: .memoryNote, db: db, storage: MediaStorageManager.shared)

        try save(sut: sut, text: "  \n  ")

        let saved = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertNil(saved.memoryNote)
        XCTAssertEqual(saved.progressStep, 6)
    }

    func test_memoryNote_withText_savesTextAndBumpsProgressStepTo6() throws {
        let keepsake = try makeKeepsake()
        let sut = TextInputViewModel(keepsakeId: keepsake.id, config: .memoryNote, db: db, storage: MediaStorageManager.shared)

        try save(sut: sut, text: "소중한 기억")

        let saved = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertEqual(saved.memoryNote, "소중한 기억")
        XCTAssertEqual(saved.progressStep, 6)
    }

    func test_lastWords_whenWhitespaceOnly_normalizesToNilButStillTransitionsStatus() throws {
        let keepsake = try makeKeepsake()
        let sut = TextInputViewModel(keepsakeId: keepsake.id, config: .lastWords, db: db, storage: MediaStorageManager.shared)

        try save(sut: sut, text: "   ")

        let saved = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertNil(saved.lastWords)
        XCTAssertNil(saved.progressStep)
        XCTAssertEqual(saved.status, .unavailable)
    }

    func test_lastWords_withText_transitionsProgressStepToNilAndStatusToUnavailable() throws {
        let keepsake = try makeKeepsake()
        XCTAssertEqual(keepsake.status, .inProgress)
        let sut = TextInputViewModel(keepsakeId: keepsake.id, config: .lastWords, db: db, storage: MediaStorageManager.shared)

        try save(sut: sut, text: "안녕")

        let saved = try XCTUnwrap(db.fetchKeepsake(id: keepsake.id))
        XCTAssertEqual(saved.lastWords, "안녕")
        XCTAssertNil(saved.progressStep)
        XCTAssertEqual(saved.status, .unavailable)
    }

    private func save(sut: TextInputViewModel, text: String) throws {
        let textSubject = PublishSubject<String>()
        let nextTapSubject = PublishSubject<Void>()
        let output = sut.transform(input: .init(text: textSubject, nextTap: nextTapSubject))
        output.navigate.subscribe().disposed(by: disposeBag)

        textSubject.onNext(text)
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
        keepsake.status = .inProgress
        keepsake.progressStep = 4
        try db.saveKeepsake(keepsake)
        return keepsake
    }
}
