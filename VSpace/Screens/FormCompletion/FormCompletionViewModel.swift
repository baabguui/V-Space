//
//  FormCompletionViewModel.swift
//  VSpace
//

import UIKit
import RealmSwift
import RxSwift

final class FormCompletionViewModel {

    struct Input {
        let primaryTap:   Observable<Void>
        let secondaryTap: Observable<Void>
    }

    struct Output {
        let goHome:     Observable<Void>
        let showRitual: Observable<Void>
    }

    let isAvailable: Bool
    let name: String
    let thumbnailImage: UIImage?

    private let keepsakeId: ObjectId
    private let db: KeepsakeDatabaseManaging

    init(
        keepsakeId: ObjectId,
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager(),
        storage: MediaStorageManaging = MediaStorageManager.shared
    ) {
        self.keepsakeId = keepsakeId
        self.db = db
        let keepsake = db.fetchKeepsake(id: keepsakeId)
        self.isAvailable = keepsake?.isAvailable ?? false
        self.name = keepsake?.name ?? ""
        self.thumbnailImage = keepsake.flatMap { storage.loadThumbnail($0.thumbnailFileName) }
    }

    func transform(input: Input) -> Output {
        // isAvailable=true: 
        // - "다음에 하기"(secondary) → 홈
        // - "시작"(primary) → 의례
        // isAvailable=false: 
        // - "홈으로"(primary) → 홈
        let goHome: Observable<Void> = isAvailable
            ? input.secondaryTap
            : input.primaryTap

        let showRitual: Observable<Void> = isAvailable
            ? input.primaryTap
            : .empty()

        return Output(goHome: goHome, showRitual: showRitual)
    }

    func scheduleNotification() {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return }
        NotificationScheduler.shared.scheduleDisposalNotification(
            keepsakeId: keepsakeId,
            name: name,
            disposalDate: keepsake.disposalDate
        )
    }
}
