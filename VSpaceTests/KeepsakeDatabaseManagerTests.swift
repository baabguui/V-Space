import XCTest
import RealmSwift
@testable import VSpace

final class KeepsakeDatabaseManagerTests: XCTestCase {

    private var sut: KeepsakeDatabaseManager!

    override func setUpWithError() throws {
        let config = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        sut = KeepsakeDatabaseManager(configuration: config)
    }

    func test_saveKeepsake_thenFetchKeepsakes_containsSavedObject() throws {
        let keepsake = makeKeepsake(name: "테스트")

        try sut.saveKeepsake(keepsake)

        XCTAssertEqual(sut.fetchKeepsakes().count, 1)
        XCTAssertEqual(sut.fetchKeepsakes().first?.name, "테스트")
    }

    func test_fetchKeepsake_withUnknownId_returnsNil() {
        XCTAssertNil(sut.fetchKeepsake(id: ObjectId.generate()))
    }

    func test_updateKeepsake_appliesChangesAndBumpsUpdatedAt() throws {
        let keepsake = makeKeepsake()
        try sut.saveKeepsake(keepsake)

        try sut.updateKeepsake(keepsake) { $0.name = "수정됨" }

        XCTAssertEqual(keepsake.name, "수정됨")
        XCTAssertLessThan(Date().timeIntervalSince(keepsake.updatedAt), 2)
    }

    func test_deleteKeepsake_removesFromFetchResults() throws {
        let keepsake = makeKeepsake()
        try sut.saveKeepsake(keepsake)

        try sut.deleteKeepsake(keepsake)

        XCTAssertEqual(sut.fetchKeepsakes().count, 0)
    }

    func test_fetchKeepsakes_returnsResultsSortedByCreatedAtDescending() throws {
        let oldest = makeKeepsake(name: "오래됨")
        oldest.createdAt = Date().addingTimeInterval(-200)
        let middle = makeKeepsake(name: "중간")
        middle.createdAt = Date().addingTimeInterval(-100)
        let newest = makeKeepsake(name: "최신")
        newest.createdAt = Date()

        try sut.saveKeepsake(oldest)
        try sut.saveKeepsake(middle)
        try sut.saveKeepsake(newest)

        let result = Array(sut.fetchKeepsakes().map { $0.name })

        XCTAssertEqual(result, ["최신", "중간", "오래됨"])
    }

    private func makeKeepsake(name: String = "기본값") -> Keepsake {
        let keepsake = Keepsake()
        keepsake.name = name
        keepsake.recordType = .photo
        keepsake.resourceFileName = "img_test.png"
        keepsake.thumbnailFileName = "thumb_test.png"
        keepsake.disposalDate = Date()
        return keepsake
    }
}

