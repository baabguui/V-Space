//
//  PartialDate.swift
//  VSpace
//
//  부분 날짜 정보(년/월/일 미상 포함)를 다루는 데이터 구조 및 포맷터
//

import Foundation

struct PartialDate: Equatable {
    let year: Int    // 0 = 미상
    let month: Int   // 0 = 미상
    let day: Int     // 0 = 미상

    static let unknown = PartialDate(year: 0, month: 0, day: 0)

    /// "2024.", "2024.3", "2024.03.15", "기억 안남" 형식 반환
    func formatted(isDisposal: Bool = false) -> String {
        if year == 0 {
            return isDisposal 
                ? NSLocalizedString("common.undecidedDate", comment: "미정")
                : NSLocalizedString("common.unknownDate", comment: "기억 안남")
        }

        if month == 0 {
            return "\(year)."
        }

        if day == 0 {
            return "\(year).\(month)"
        }

        // 전체 있을 경우 yyyy.MM.dd (시스템 로케일 무시하고 앱 컨셉에 맞춰 점으로 구분)
        return String(format: "%04d.%02d.%02d", year, month, day)
    }

    /// 두 PartialDate 간 근사 기간: "약 2년 3개월 동안" 반환 (nil = 계산 불가)
    static func approximateDuration(from: PartialDate, to: PartialDate) -> String? {
        // 둘 중 하나라도 연도가 없으면 계산 불가
        guard from.year > 0, to.year > 0 else { return nil }

        // 월이 없으면 해당 연도의 중간(6월)으로 가정하여 근사 계산
        let fromM = from.month > 0 ? from.month : 6
        let toM = to.month > 0 ? to.month : 6

        let totalMonths = (to.year - from.year) * 12 + (toM - fromM)

        if totalMonths < 0 { return nil }
        if totalMonths == 0 { return nil }

        let years = totalMonths / 12
        let months = totalMonths % 12

        var durationParts: [String] = []
        if years > 0 {
            durationParts.append(String(format: NSLocalizedString("common.durationYear", comment: ""), years))
        }
        if months > 0 {
            durationParts.append(String(format: NSLocalizedString("common.durationMonth", comment: ""), months))
        }

        if durationParts.isEmpty { return nil }

        let durationStr = durationParts.joined(separator: " ")
        return String(format: NSLocalizedString("common.approximateDuration", comment: ""), durationStr)
    }
}
