//
//  FormCompletionViewModel.swift
//  VSpace
//

import Foundation
import RealmSwift
import RxSwift

final class FormCompletionViewModel {

    struct Input {
        let primaryTap:   Observable<Void>
        let secondaryTap: Observable<Void>
    }

    struct Output {
        let goHome: Observable<Void>
        // TODO: startRitual (isAvailable=true → primaryTap)
        // TODO: requestNotification (isAvailable=false → secondaryTap)
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
        // isAvailable=true: "다음에 하기"(secondary) → 홈
        // isAvailable=false: "홈으로"(primary) → 홈
        let goHome: Observable<Void> = isAvailable
            ? input.secondaryTap
            : input.primaryTap

        return Output(goHome: goHome)
    }
}
