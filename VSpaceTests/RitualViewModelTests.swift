import XCTest
import RealmSwift
@testable import VSpace

final class RitualViewModelTests: XCTestCase {

    private var db: KeepsakeDatabaseManager!

    override func setUpWithError() throws {
        let config = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        db = KeepsakeDatabaseManager(configuration: config)
    }

    // MARK: - scale(for:) 경계값
    // 실제 구현은 threshold=4에서 시작해 ×4씩 증가(4/16/64/256)하며 레벨이 올라간다.
    // 메서드 주석에 적힌 "3~8/9~26/27~80/81+" 경계(3의 거듭제곱 기준)와는 실제로 일치하지 않는다.
    // 아래 테스트는 실제 동작(4의 거듭제곱 경계)을 기준으로 작성했다.

    func test_scale_belowFirstThreshold_isFullScale() {
        XCTAssertEqual(RitualViewModel.scale(for: 0), 1.0)
        XCTAssertEqual(RitualViewModel.scale(for: 3), 1.0)
    }

    func test_scale_atFirstThreshold_dropsOneLevel() {
        XCTAssertEqual(RitualViewModel.scale(for: 4), 0.85, accuracy: 0.0001)
    }

    func test_scale_justBelowSecondThreshold_staysAtFirstLevel() {
        XCTAssertEqual(RitualViewModel.scale(for: 15), 0.85, accuracy: 0.0001)
    }

    func test_scale_atSecondThreshold_dropsTwoLevels() {
        XCTAssertEqual(RitualViewModel.scale(for: 16), 0.70, accuracy: 0.0001)
    }

    func test_scale_justBelowThirdThreshold_staysAtSecondLevel() {
        XCTAssertEqual(RitualViewModel.scale(for: 63), 0.70, accuracy: 0.0001)
    }

    func test_scale_atThirdThreshold_dropsThreeLevels() {
        XCTAssertEqual(RitualViewModel.scale(for: 64), 0.55, accuracy: 0.0001)
    }

    func test_scale_justBelowFourthThreshold_staysAtThirdLevel() {
        XCTAssertEqual(RitualViewModel.scale(for: 255), 0.55, accuracy: 0.0001)
    }

    func test_scale_atFourthThreshold_reachesMinimumScale() {
        XCTAssertEqual(RitualViewModel.scale(for: 256), 0.40, accuracy: 0.0001)
    }

    func test_scale_wellBeyondFourthThreshold_clampsAtMinimum() {
        XCTAssertEqual(RitualViewModel.scale(for: 100_000), 0.40, accuracy: 0.0001)
    }

    // MARK: - cardDetailText의 을/를 조사 (eulReul, private 중복 함수의 간접 검증)

    func test_cardDetailText_withBatchimAbility_usesEulJosa() throws {
        let keepsake = try makeKeepsake(ability: "사랑")
        let sut = RitualViewModel(keepsakeId: keepsake.id, db: db)

        let expectedAbilityStr = String(format: NSLocalizedString("ritual.cardDetail.ability", comment: ""), "사랑", "을 ")
        XCTAssertTrue(sut.cardDetailText.contains(expectedAbilityStr))
    }

    func test_cardDetailText_withoutBatchimAbility_usesReulJosa() throws {
        let keepsake = try makeKeepsake(ability: "커피")
        let sut = RitualViewModel(keepsakeId: keepsake.id, db: db)

        let expectedAbilityStr = String(format: NSLocalizedString("ritual.cardDetail.ability", comment: ""), "커피", "를 ")
        XCTAssertTrue(sut.cardDetailText.contains(expectedAbilityStr))
    }

    // MARK: - 하위 호환성 (레거시 Date → PartialDate 변환)

    func test_cardDetailText_legacyAcquiredDate_isConvertedToPartialDateForDuration() throws {
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

        let sut = RitualViewModel(keepsakeId: keepsake.id, db: db)

        let durationStr = String(format: NSLocalizedString("common.durationYear", comment: ""), 10)
            + " "
            + String(format: NSLocalizedString("common.durationMonth", comment: ""), 1)
        let expectedDuration = String(format: NSLocalizedString("common.approximateDuration", comment: ""), durationStr)
        XCTAssertTrue(sut.cardDetailText.contains(expectedDuration))
    }

    func test_cardDetailText_legacyDisposalDate_isConvertedToPartialDateForDuration() throws {
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

        let sut = RitualViewModel(keepsakeId: keepsake.id, db: db)

        let durationStr = String(format: NSLocalizedString("common.durationYear", comment: ""), 10)
            + " "
            + String(format: NSLocalizedString("common.durationMonth", comment: ""), 1)
        let expectedDuration = String(format: NSLocalizedString("common.approximateDuration", comment: ""), durationStr)
        XCTAssertTrue(sut.cardDetailText.contains(expectedDuration))
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
