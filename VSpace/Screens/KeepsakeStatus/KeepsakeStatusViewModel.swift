//
//  KeepsakeStatusViewModel.swift
//  VSpace
//

import Foundation
import RealmSwift
import RxSwift

final class KeepsakeStatusViewModel {

    struct Input {
        let primaryTap:   Observable<Void>
        let secondaryTap: Observable<Void>
    }

    struct Output {
        let showRitual: Observable<Void>
        // TODO: secondaryTap → KeepsakeFormCoordinator에서 처리 예정
    }

    // MARK: - Properties

    let isAvailable: Bool
    let name: String

    private let db: KeepsakeDatabaseManaging

    // MARK: - Init

    init(keepsakeId: ObjectId, db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager()) {
        self.db = db
        let keepsake = db.fetchKeepsake(id: keepsakeId)
        self.isAvailable = keepsake?.isAvailable ?? false
        self.name        = keepsake?.name ?? ""
    }

    // MARK: - Transform

    func transform(input: Input) -> Output {
        return Output(showRitual: input.primaryTap.asObservable())
    }
}
