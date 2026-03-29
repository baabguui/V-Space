//
//  NameInputViewModel.swift
//  VSpace
//

import UIKit
import RealmSwift
import RxSwift
import RxRelay

final class NameInputViewModel {

    struct Input {
        let name:    Observable<String>
        let nextTap: Observable<Void>
    }

    struct Output {
        let isNextEnabled: Observable<Bool>
        let navigateNext:  Observable<ObjectId>
    }

    private let keepsakeId: ObjectId
    private let db: KeepsakeDatabaseManaging
    private let storage: MediaStorageManaging
    private let disposeBag = DisposeBag()

    var initialName: String { db.fetchKeepsake(id: keepsakeId)?.name ?? "" }

    var thumbnailImage: UIImage? {
        guard let fileName = db.fetchKeepsake(id: keepsakeId)?.thumbnailFileName else { return nil }
        return storage.loadThumbnail(fileName)
    }

    init(
        keepsakeId: ObjectId,
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager(),
        storage: MediaStorageManaging = MediaStorageManager.shared
    ) {
        self.keepsakeId = keepsakeId
        self.db = db
        self.storage = storage
    }

    func transform(input: Input) -> Output {
        let isNextEnabled = input.name
            .map { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        let navigateNext = input.nextTap
            .withLatestFrom(input.name)
            .compactMap { [weak self] name -> ObjectId? in
                self?.save(name: name)
            }

        return Output(isNextEnabled: isNextEnabled, navigateNext: navigateNext)
    }

    private func save(name: String) -> ObjectId? {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return nil }
        try? db.updateKeepsake(keepsake) {
            $0.name = name
            $0.progressStep = 2
        }
        return keepsakeId
    }
}
