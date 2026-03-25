//
//  Keepsake.swift
//  VSpace
//
//  Realm 데이터베이스 모델 — 추억 물건(유품) 데이터 관리
//

import Foundation
import RealmSwift

// MARK: - Enums

enum FuneralStatus: String, PersistableEnum {
    case inProgress  = "IN_PROGRESS"
    case available   = "AVAILABLE"
    case unavailable = "UNAVAILABLE"
    case done        = "DONE"
}

enum RecordType: String, PersistableEnum {
    case threeD    = "THREE_D"
    case photo     = "PHOTO"
    case fragment  = "FRAGMENT"
}

// MARK: - Model

final class Keepsake: Object {
    @Persisted(primaryKey: true) var id: ObjectId

    // 기본 정보
    @Persisted var name: String
    @Persisted var ability: String?
    @Persisted var memoryNote: String?
    @Persisted var lastWords: String?

    // 날짜
    @Persisted var acquiredDate: Date?
    @Persisted var disposalDate: Date
    @Persisted var ritualDate: Date
    @Persisted var createdAt: Date = Date()
    @Persisted var updatedAt: Date = Date()

    // 상태
    @Persisted var status: FuneralStatus = .unavailable
    @Persisted var progressStep: Int?     // inProgress일 때만 유효

    // 타입 및 파일
    @Persisted var recordType: RecordType
    @Persisted var resourceFileName: String
    @Persisted var thumbnailFileName: String
}

extension Keepsake {
    // available/unavailable은 계산으로 처리
    var isAvailable: Bool { Date() >= disposalDate }
}
