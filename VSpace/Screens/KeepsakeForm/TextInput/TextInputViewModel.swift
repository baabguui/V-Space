//
//  TextInputViewModel.swift
//  VSpace
//

import UIKit
import RealmSwift
import RxSwift

final class TextInputViewModel {

    struct Input {
        let text:    Observable<String>
        let nextTap: Observable<Void>
        let skipTap: Observable<Void>
    }

    struct Output {
        let navigateNext: Observable<ObjectId>
        let navigateSkip: Observable<ObjectId>
    }

    private let keepsakeId: ObjectId
    private let config: TextInputConfig
    private let db: KeepsakeDatabaseManaging
    private let storage: MediaStorageManaging

    var thumbnailImage: UIImage? {
        guard let fileName = db.fetchKeepsake(id: keepsakeId)?.thumbnailFileName else { return nil }
        return storage.loadThumbnail(fileName)
    }

    var initialText: String {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return "" }
        switch config {
        case .ability:    return keepsake.ability ?? ""
        case .memoryNote: return keepsake.memoryNote ?? ""
        case .lastWords:  return keepsake.lastWords ?? ""
        }
    }

    init(
        keepsakeId: ObjectId,
        config: TextInputConfig,
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
            .withLatestFrom(input.text)
            .compactMap { [weak self] text -> ObjectId? in
                self?.save(text: text)
            }

        let navigateSkip = input.skipTap
            .compactMap { [weak self] _ -> ObjectId? in
                self?.advanceStep()
            }

        return Output(navigateNext: navigateNext, navigateSkip: navigateSkip)
    }

    private func save(text: String) -> ObjectId? {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return nil }
        try? db.updateKeepsake(keepsake) { k in
            let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
            switch self.config {
            case .ability:
                k.ability = value.isEmpty ? nil : value
                k.progressStep = 5
            case .memoryNote:
                k.memoryNote = value.isEmpty ? nil : value
                k.progressStep = 6
            case .lastWords:
                k.lastWords = value.isEmpty ? nil : value
                k.status = .unavailable
                k.progressStep = nil
            }
        }
        return keepsakeId
    }

    private func advanceStep() -> ObjectId? {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return nil }
        try? db.updateKeepsake(keepsake) { k in
            switch self.config {
            case .ability:    k.progressStep = 5
            case .memoryNote: k.progressStep = 6
            case .lastWords:  k.status = .unavailable; k.progressStep = nil
            }
        }
        return keepsakeId
    }
}
