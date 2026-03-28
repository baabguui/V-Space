//
//  KeepsakeDetailViewModel.swift
//  VSpace
//

import UIKit
import RealmSwift
import RxSwift

final class KeepsakeDetailViewModel {

    // MARK: - Types

    struct Input {
        let closeTap: Observable<Void>
    }

    struct Output {
        let navigateDone: Observable<Void>
    }

    // MARK: - Display Data

    let thumbnailImage: UIImage?
    let keepsakeName: String
    let dateRangeText: String
    let lastWords: String
    let ability: String
    let memoryNote: String
    let ritualDateText: String
    let mournyCountText: String
    let mournyImageNames: [String]
    let showsCloseButton: Bool

    // MARK: - Original Content

    let recordType: RecordType
    private let resourceFileName: String
    private let storage: MediaStorageManaging

    lazy var originalImage: UIImage? = {
        guard recordType == .photo else { return nil }
        return storage.loadPhoto(resourceFileName)
    }()

    lazy var modelURL: URL? = {
        guard recordType == .threeD else { return nil }
        return storage.modelURL(for: resourceFileName)
    }()

    // MARK: - Init

    init(
        keepsakeId: ObjectId,
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager(),
        storage: MediaStorageManaging = MediaStorageManager.shared,
        showsCloseButton: Bool
    ) {
        self.showsCloseButton = showsCloseButton
        self.storage = storage

        let keepsake = db.fetchKeepsake(id: keepsakeId)
        self.recordType = keepsake?.recordType ?? .fragment
        self.resourceFileName = keepsake?.resourceFileName ?? ""
        self.thumbnailImage = keepsake
            .flatMap { storage.loadThumbnail($0.thumbnailFileName) }
        self.keepsakeName = keepsake?.name ?? ""
        self.lastWords    = keepsake?.lastWords ?? ""
        self.ability      = keepsake?.ability ?? ""
        self.memoryNote   = keepsake?.memoryNote ?? ""

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let disposalStr = keepsake.map { formatter.string(from: $0.disposalDate) } ?? ""
        if let acquired = keepsake?.acquiredDate {
            self.dateRangeText = String(format: NSLocalizedString("common.dateRange.separator", comment: ""), formatter.string(from: acquired), disposalStr)
        } else {
            self.dateRangeText = disposalStr
        }
        let ritualDate = keepsake?.ritualDate ?? Date()
        self.ritualDateText = formatter.string(from: ritualDate)

        let count = keepsake?.mournyCount ?? 0
        self.mournyCountText = String(format: NSLocalizedString("keepsakeDetail.label.mournyCount", comment: ""), count)

        let pool = ["frontMournyA", "frontMournyB", "frontMournyC", "horizontalMournyA", "horizontalMournyB"]
        self.mournyImageNames = (0..<min(count, 9)).map { _ in pool.randomElement()! }
    }

    // MARK: - Transform

    func transform(input: Input) -> Output {
        Output(navigateDone: input.closeTap)
    }
}
