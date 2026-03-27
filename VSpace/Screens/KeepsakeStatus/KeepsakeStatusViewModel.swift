//
//  KeepsakeStatusViewModel.swift
//  VSpace
//

import Foundation
import RealmSwift
import RxSwift

final class KeepsakeStatusViewModel {

    struct Input {
        let primaryTap:   Observable<Void>  // "예 (진행)" or "오늘 날짜로 진행"
        let secondaryTap: Observable<Void>  // "날짜 바꾸기"
    }

    struct Output {
        // TODO: confirmRitual (primaryTap → done 전환)
        // TODO: changeDate   (secondaryTap → 날짜 변경 화면)
    }

    let isAvailable: Bool
    let name: String

    private let db: KeepsakeDatabaseManaging

    init(keepsakeId: ObjectId, db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager()) {
        self.db = db
        let keepsake = db.fetchKeepsake(id: keepsakeId)
        self.isAvailable = keepsake?.isAvailable ?? false
        self.name = keepsake?.name ?? ""
    }

    func transform(input: Input) -> Output {
        return Output()
    }
}
