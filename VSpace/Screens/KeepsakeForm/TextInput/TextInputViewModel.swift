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
    }

    struct Output {
        let navigate: Observable<ObjectId>
    }

    private let keepsakeId: ObjectId
    private let config: TextInputConfig
    private let db: KeepsakeDatabaseManaging
    private let storage: MediaStorageManaging
    private let analytics: AnalyticsTracking

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
        storage: MediaStorageManaging = MediaStorageManager.shared,
        analytics: AnalyticsTracking = AnalyticsTracker.shared
    ) {
        self.keepsakeId = keepsakeId
        self.config = config
        self.db = db
        self.storage = storage
        self.analytics = analytics
    }

    func transform(input: Input) -> Output {
        let navigate = input.nextTap
            .withLatestFrom(input.text)
            .compactMap { [weak self] text -> ObjectId? in
                self?.save(text: text)
            }

        return Output(navigate: navigate)
    }

    private func save(text: String) -> ObjectId? {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return nil }
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let recordType = keepsake.recordType
        try? db.updateKeepsake(keepsake) { k in
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

        let step: String
        var isLastWords = false
        switch config {
        case .ability:    step = "ability"
        case .memoryNote: step = "memory_note"
        case .lastWords:  step = "last_words"; isLastWords = true
        }
        analytics.log(.formInputAction(step: step, action: value.isEmpty ? "skip" : "next"))
        if isLastWords {
            analytics.log(.keepsakeCreated(recordType: recordType == .threeD ? "three_d" : "photo"))
        }

        return keepsakeId
    }
}
