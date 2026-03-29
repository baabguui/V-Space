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

    private static let defaultLastWordsCandidates = [
        "ritual.defaultLastWords.1",
        "ritual.defaultLastWords.2",
        "ritual.defaultLastWords.3",
        "ritual.defaultLastWords.4",
        "ritual.defaultLastWords.5"
    ]

    private static func randomDefaultLastWords() -> String {
        let key = defaultLastWordsCandidates.randomElement()!
        return NSLocalizedString(key, comment: "")
    }

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
        
        self.lastWords    = keepsake?.lastWords.flatMap { $0.isEmpty ? nil : $0 } 
                            ?? Self.randomDefaultLastWords()
        self.ability      = keepsake?.ability.flatMap { $0.isEmpty ? nil : $0 } 
                            ?? NSLocalizedString("keepsake.defaultAbility", comment: "함께 하기")
        self.memoryNote   = keepsake?.memoryNote ?? ""

        // PartialDate 기반 날짜 섹션
        let acquired = PartialDate(
            year: keepsake?.acquiredYear ?? 0,
            month: keepsake?.acquiredMonth ?? 0,
            day: keepsake?.acquiredDay ?? 0
        )
        let disposal = PartialDate(
            year: keepsake?.disposalYear ?? 0,
            month: keepsake?.disposalMonth ?? 0,
            day: keepsake?.disposalDay ?? 0
        )

        // 하위 호환성
        let finalAcquired = (acquired.year == 0 && keepsake?.acquiredDate != nil)
            ? PartialDate(
                year: Calendar.current.component(.year, from: (keepsake?.acquiredDate)!),
                month: Calendar.current.component(.month, from: (keepsake?.acquiredDate)!),
                day: Calendar.current.component(.day, from: (keepsake?.acquiredDate)!)
              )
            : acquired

        let finalDisposal = (disposal.year == 0 && keepsake?.disposalDate != .distantFuture)
            ? PartialDate(
                year: Calendar.current.component(.year, from: (keepsake?.disposalDate)!),
                month: Calendar.current.component(.month, from: (keepsake?.disposalDate)!),
                day: Calendar.current.component(.day, from: (keepsake?.disposalDate)!)
              )
            : disposal

        if finalAcquired.year == 0 && finalDisposal.year == 0 {
            self.dateRangeText = NSLocalizedString("common.unknownDate", comment: "기억 안남")
        } else if finalAcquired.year == 0 {
            self.dateRangeText = finalDisposal.formatted(isDisposal: true)
        } else {
            self.dateRangeText = String(format: NSLocalizedString("common.dateRange.separator", comment: ""), 
                                        finalAcquired.formatted(), 
                                        finalDisposal.formatted(isDisposal: true))
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
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
