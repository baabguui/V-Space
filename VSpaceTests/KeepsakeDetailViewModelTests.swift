import XCTest
import RealmSwift
@testable import VSpace

final class KeepsakeDetailViewModelTests: XCTestCase {

    private var db: KeepsakeDatabaseManager!

    override func setUpWithError() throws {
        let config = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        db = KeepsakeDatabaseManager(configuration: config)
    }

    // MARK: - abilityDetailText의 을/를 조사 (eulReul, private 중복 함수의 간접 검증)

    func test_abilityDetailText_withBatchimAbility_usesEulJosa() throws {
        let keepsake = try makeKeepsake(ability: "사랑")
        let sut = KeepsakeDetailViewModel(keepsakeId: keepsake.id, db: db, storage: MediaStorageManager.shared, showsCloseButton: false)

        let expectedAbilityStr = String(format: NSLocalizedString("ritual.cardDetail.ability", comment: ""), "사랑", "을 ")
        XCTAssertTrue(sut.abilityDetailText.contains(expectedAbilityStr))
    }

    func test_abilityDetailText_withoutBatchimAbility_usesReulJosa() throws {
        let keepsake = try makeKeepsake(ability: "커피")
        let sut = KeepsakeDetailViewModel(keepsakeId: keepsake.id, db: db, storage: MediaStorageManager.shared, showsCloseButton: false)

        let expectedAbilityStr = String(format: NSLocalizedString("ritual.cardDetail.ability", comment: ""), "커피", "를 ")
        XCTAssertTrue(sut.abilityDetailText.contains(expectedAbilityStr))
    }

    // MARK: - 하위 호환성 (레거시 Date → PartialDate 변환)

    func test_dateRangeText_legacyAcquiredDate_isConvertedToPartialDate() throws {
        let keepsake = try makeKeepsake(ability: "사랑")
        let acquiredLegacyDate = Calendar.current.date(from: DateComponents(year: 2010, month: 5, day: 20, hour: 12))!
        try db.updateKeepsake(keepsake) {
            $0.acquiredYear = 0
            $0.acquiredMonth = 0
            $0.acquiredDay = 0
            $0.acquiredDate = acquiredLegacyDate
            $0.disposalYear = 2020
            $0.disposalMonth = 6
            $0.disposalDay = 15
        }

        let sut = KeepsakeDetailViewModel(keepsakeId: keepsake.id, db: db, storage: MediaStorageManager.shared, showsCloseButton: false)

        let expected = String(
            format: NSLocalizedString("common.dateRange.separator", comment: ""),
            "2010.05.20",
            PartialDate(year: 2020, month: 6, day: 15).formatted(isDisposal: true)
        )
        XCTAssertEqual(sut.dateRangeText, expected)
    }

    func test_dateRangeText_legacyDisposalDate_isConvertedToPartialDate() throws {
        let keepsake = try makeKeepsake(ability: "사랑")
        let disposalLegacyDate = Calendar.current.date(from: DateComponents(year: 2020, month: 6, day: 15, hour: 12))!
        try db.updateKeepsake(keepsake) {
            $0.acquiredYear = 2010
            $0.acquiredMonth = 5
            $0.acquiredDay = 20
            $0.disposalYear = 0
            $0.disposalMonth = 0
            $0.disposalDay = 0
            $0.disposalDate = disposalLegacyDate
        }

        let sut = KeepsakeDetailViewModel(keepsakeId: keepsake.id, db: db, storage: MediaStorageManager.shared, showsCloseButton: false)

        let expected = String(
            format: NSLocalizedString("common.dateRange.separator", comment: ""),
            PartialDate(year: 2010, month: 5, day: 20).formatted(),
            "2020.06.15"
        )
        XCTAssertEqual(sut.dateRangeText, expected)
    }

    // MARK: - Fixtures

    @discardableResult
    private func makeKeepsake(ability: String) throws -> Keepsake {
        let keepsake = Keepsake()
        keepsake.name = "기본값"
        keepsake.ability = ability
        keepsake.recordType = .photo
        keepsake.resourceFileName = "img_test.png"
        keepsake.thumbnailFileName = "thumb_test.png"
        keepsake.disposalDate = .distantFuture
        try db.saveKeepsake(keepsake)
        return keepsake
    }
}
