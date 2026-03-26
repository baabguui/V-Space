//
//  DateInputViewModel.swift
//  VSpace
//

import Foundation
import RealmSwift
import RxSwift

final class DateInputViewModel {

    struct Input {
        let date:    Observable<Date>
        let nextTap: Observable<Void>
    }

    struct Output {
        let navigateNext: Observable<ObjectId>
    }

    private let keepsakeId: ObjectId
    private let config: DateInputConfig
    private let db: KeepsakeDatabaseManaging

    var initialDate: Date {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return Date() }
        switch config {
        case .acquiredDate: return keepsake.acquiredDate ?? Date()
        case .disposalDate: return keepsake.disposalDate
        }
    }

    init(
        keepsakeId: ObjectId,
        config: DateInputConfig,
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager()
    ) {
        self.keepsakeId = keepsakeId
        self.config = config
        self.db = db
    }

    func transform(input: Input) -> Output {
        let navigateNext = input.nextTap
            .withLatestFrom(input.date)
            .compactMap { [weak self] date -> ObjectId? in
                self?.save(date: date)
            }

        return Output(navigateNext: navigateNext)
    }

    private func save(date: Date) -> ObjectId? {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return nil }
        try? db.updateKeepsake(keepsake) { k in
            switch self.config {
            case .acquiredDate:
                k.acquiredDate = date
                k.progressStep = 3
            case .disposalDate:
                k.disposalDate = date
                k.progressStep = 4
            }
        }
        return keepsakeId
    }
}
