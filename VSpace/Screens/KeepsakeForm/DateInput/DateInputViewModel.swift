//
//  DateInputViewModel.swift
//  VSpace
//

import UIKit
import RealmSwift
import RxSwift

final class DateInputViewModel {

    struct Input {
        let date:    Observable<PartialDate>
        let nextTap: Observable<Void>
    }

    struct Output {
        let navigateNext: Observable<ObjectId>
    }

    private let keepsakeId: ObjectId
    private let config: DateInputConfig
    private let db: KeepsakeDatabaseManaging
    private let storage: MediaStorageManaging

    var thumbnailImage: UIImage? {
        guard let fileName = db.fetchKeepsake(id: keepsakeId)?.thumbnailFileName else { return nil }
        return storage.loadThumbnail(fileName)
    }

    var initialPartialDate: PartialDate {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return .unknown }
        switch config {
        case .acquiredDate:
            return PartialDate(
                year: keepsake.acquiredYear,
                month: keepsake.acquiredMonth,
                day: keepsake.acquiredDay
            )
        case .disposalDate:
            return PartialDate(
                year: keepsake.disposalYear,
                month: keepsake.disposalMonth,
                day: keepsake.disposalDay
            )
        }
    }

    init(
        keepsakeId: ObjectId,
        config: DateInputConfig,
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager(),
        storage: MediaStorageManaging = MediaStorageManager.shared
    ) {
        self.keepsakeId = keepsakeId
        self.config = config
        self.db = db
        self.storage = storage
    }

    func transform(input: Input) -> Output {
        let navigateNext = input.nextTap
            .withLatestFrom(input.date)
            .compactMap { [weak self] partial -> ObjectId? in
                self?.save(partial: partial)
            }

        return Output(navigateNext: navigateNext)
    }

    private func save(partial: PartialDate) -> ObjectId? {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return nil }
        
        // Date 객체 생성 (isAvailable 등 기존 로직용)
        let date: Date?
        if partial.year > 0 && partial.month > 0 && partial.day > 0 {
            var comps = DateComponents()
            comps.year = partial.year; comps.month = partial.month; comps.day = partial.day
            date = Calendar.current.date(from: comps)
        } else {
            date = nil
        }

        try? db.updateKeepsake(keepsake) { k in
            switch self.config {
            case .acquiredDate:
                k.acquiredDate  = date
                k.acquiredYear  = partial.year
                k.acquiredMonth = partial.month
                k.acquiredDay   = partial.day
                k.progressStep  = 3
            case .disposalDate:
                k.disposalDate  = date ?? .distantFuture
                k.disposalYear  = partial.year
                k.disposalMonth = partial.month
                k.disposalDay   = partial.day
                k.progressStep  = 4
            }
        }
        return keepsakeId
    }
}
