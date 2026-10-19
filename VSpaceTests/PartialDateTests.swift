import XCTest
@testable import VSpace

final class PartialDateTests: XCTestCase {

    // MARK: - formatted

    func test_formatted_yearZero_notDisposal_returnsUnknownDateString() {
        let date = PartialDate(year: 0, month: 0, day: 0)

        let expected = NSLocalizedString("common.unknownDate", comment: "")
        XCTAssertEqual(date.formatted(isDisposal: false), expected)
    }

    func test_formatted_yearZero_disposal_returnsUndecidedDateString() {
        let date = PartialDate(year: 0, month: 0, day: 0)

        let expected = NSLocalizedString("common.undecidedDate", comment: "")
        XCTAssertEqual(date.formatted(isDisposal: true), expected)
    }

    func test_formatted_yearOnly_returnsYearWithDot() {
        let date = PartialDate(year: 2024, month: 0, day: 0)

        XCTAssertEqual(date.formatted(), "2024.")
    }

    func test_formatted_yearAndMonth_dayZero_returnsYearDotMonth() {
        let date = PartialDate(year: 2024, month: 3, day: 0)

        XCTAssertEqual(date.formatted(), "2024.3")
    }

    func test_formatted_fullDate_returnsZeroPaddedYyyyMmDd() {
        let date = PartialDate(year: 2024, month: 3, day: 5)

        XCTAssertEqual(date.formatted(), "2024.03.05")
    }

    // MARK: - approximateDuration

    func test_approximateDuration_fromYearZero_returnsNil() {
        let from = PartialDate(year: 0, month: 0, day: 0)
        let to = PartialDate(year: 2022, month: 3, day: 0)

        XCTAssertNil(PartialDate.approximateDuration(from: from, to: to))
    }

    func test_approximateDuration_toYearZero_returnsNil() {
        let from = PartialDate(year: 2020, month: 1, day: 0)
        let to = PartialDate(year: 0, month: 0, day: 0)

        XCTAssertNil(PartialDate.approximateDuration(from: from, to: to))
    }

    func test_approximateDuration_withMonths_returnsYearAndMonthDuration() {
        let from = PartialDate(year: 2020, month: 1, day: 0)
        let to = PartialDate(year: 2022, month: 3, day: 0)

        let durationStr = String(format: NSLocalizedString("common.durationYear", comment: ""), 2)
            + " "
            + String(format: NSLocalizedString("common.durationMonth", comment: ""), 2)
        let expected = String(format: NSLocalizedString("common.approximateDuration", comment: ""), durationStr)

        XCTAssertEqual(PartialDate.approximateDuration(from: from, to: to), expected)
    }

    func test_approximateDuration_fromMonthZero_assumesJune() {
        // from = 2020년 (월 미상, 6월로 가정), to = 2020.09 → 3개월
        let from = PartialDate(year: 2020, month: 0, day: 0)
        let to = PartialDate(year: 2020, month: 9, day: 0)

        let durationStr = String(format: NSLocalizedString("common.durationMonth", comment: ""), 3)
        let expected = String(format: NSLocalizedString("common.approximateDuration", comment: ""), durationStr)

        XCTAssertEqual(PartialDate.approximateDuration(from: from, to: to), expected)
    }

    func test_approximateDuration_toMonthZero_assumesJune() {
        // from = 2020.03, to = 2021년 (월 미상, 6월로 가정) → 15개월 = 1년 3개월
        let from = PartialDate(year: 2020, month: 3, day: 0)
        let to = PartialDate(year: 2021, month: 0, day: 0)

        let durationStr = String(format: NSLocalizedString("common.durationYear", comment: ""), 1)
            + " "
            + String(format: NSLocalizedString("common.durationMonth", comment: ""), 3)
        let expected = String(format: NSLocalizedString("common.approximateDuration", comment: ""), durationStr)

        XCTAssertEqual(PartialDate.approximateDuration(from: from, to: to), expected)
    }

    func test_approximateDuration_toBeforeFrom_returnsNil() {
        let from = PartialDate(year: 2022, month: 1, day: 0)
        let to = PartialDate(year: 2020, month: 1, day: 0)

        XCTAssertNil(PartialDate.approximateDuration(from: from, to: to))
    }

    func test_approximateDuration_samePoint_returnsNil() {
        let from = PartialDate(year: 2020, month: 5, day: 0)
        let to = PartialDate(year: 2020, month: 5, day: 0)

        XCTAssertNil(PartialDate.approximateDuration(from: from, to: to))
    }

    func test_approximateDuration_exactYearsNoMonths_omitsMonthPart() {
        let from = PartialDate(year: 2020, month: 1, day: 0)
        let to = PartialDate(year: 2023, month: 1, day: 0)

        let durationStr = String(format: NSLocalizedString("common.durationYear", comment: ""), 3)
        let expected = String(format: NSLocalizedString("common.approximateDuration", comment: ""), durationStr)

        XCTAssertEqual(PartialDate.approximateDuration(from: from, to: to), expected)
    }

    func test_approximateDuration_exactMonthsNoYears_omitsYearPart() {
        let from = PartialDate(year: 2020, month: 1, day: 0)
        let to = PartialDate(year: 2020, month: 6, day: 0)

        let durationStr = String(format: NSLocalizedString("common.durationMonth", comment: ""), 5)
        let expected = String(format: NSLocalizedString("common.approximateDuration", comment: ""), durationStr)

        XCTAssertEqual(PartialDate.approximateDuration(from: from, to: to), expected)
    }
}
