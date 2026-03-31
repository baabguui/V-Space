//
//  KeepsakeStatusViewModel.swift
//  VSpace
//

import UIKit
import RealmSwift
import RxSwift

final class KeepsakeStatusViewModel {

    struct Input {
        let primaryTap:   Observable<Void>
        let secondaryTap: Observable<Void>
    }

    struct Output {
        let showRitual:           Observable<Void>
        let showDisposalDateEdit: Observable<Void>
    }

    // MARK: - Properties

    let isAvailable: Bool
    let name: String
    let thumbnailImage: UIImage?

    private let keepsakeId: ObjectId
    private let db: KeepsakeDatabaseManaging
    private let storage: MediaStorageManaging

    // MARK: - Init

    init(
        keepsakeId: ObjectId,
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager(),
        storage: MediaStorageManaging = MediaStorageManager.shared
    ) {
        self.keepsakeId = keepsakeId
        self.db = db
        self.storage = storage
        let keepsake = db.fetchKeepsake(id: keepsakeId)
        self.isAvailable    = keepsake?.isAvailable ?? false
        self.name           = keepsake?.name ?? ""
        self.thumbnailImage = keepsake.flatMap { storage.loadThumbnail($0.thumbnailFileName) }
    }

    // MARK: - Transform

    func transform(input: Input) -> Output {
        let showRitual = input.primaryTap
            .do(onNext: { [weak self] in
                guard let self, !self.isAvailable else { return }
                self.updateDisposalDateToToday()
            })
            .asObservable()

        let showDisposalDateEdit = input.secondaryTap.asObservable()

        return Output(showRitual: showRitual, showDisposalDateEdit: showDisposalDateEdit)
    }

    // MARK: - Actions

    func deleteKeepsake() {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return }
        storage.deleteKeepsakeFiles(
            resourceFileName: keepsake.resourceFileName,
            thumbnailFileName: keepsake.thumbnailFileName,
            recordType: keepsake.recordType
        )
        try? db.deleteKeepsake(keepsake)
    }

    // MARK: - Private

    private func updateDisposalDateToToday() {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return }
        try? db.updateKeepsake(keepsake) { $0.disposalDate = Date() }
    }
}
