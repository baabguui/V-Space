//
//  RitualViewModel.swift
//  VSpace
//

import UIKit
import RealmSwift
import RxSwift

final class RitualViewModel {

    // MARK: - Types

    typealias MournyEventSelector = () -> MournyEvent

    struct Input {
        let imageTap: Observable<Void>
        let nextTap:  Observable<Void>
    }

    struct Output {
        let mournySpawn:      Observable<MournySpawn>
        let scaleDidChange:   Observable<CGFloat>
        let showNextButton:   Observable<Bool>
        let enterDonePhase:   Observable<Void>
        let enterCardPhase:   Observable<Void>
        let navigateToDetail: Observable<Void>
    }

    // MARK: - Properties

    let thumbnailImage: UIImage?
    let lastWords: String
    let keepsakeName: String
    let cardDetailText: String

    private let keepsakeId: ObjectId
    private let db: KeepsakeDatabaseManaging
    private let mournySelector: MournyEventSelector
    private let disposeBag = DisposeBag()

    private static let defaultLastWordsCandidates = [
        "ritual.defaultLastWords.1", // "고마워"
        "ritual.defaultLastWords.2", // "잘 지내"
        "ritual.defaultLastWords.3", // "보고 싶을 거야"
        "ritual.defaultLastWords.4", // "수고했어"
    ]

    private static func randomDefaultLastWords() -> String {
        let key = defaultLastWordsCandidates.randomElement()!
        return NSLocalizedString(key, comment: "")
    }

    // MARK: - Init

    init(
        keepsakeId: ObjectId,
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager(),
        mournySelector: @escaping MournyEventSelector = MournyEvent.random
    ) {
        self.keepsakeId = keepsakeId
        self.db = db
        self.mournySelector = mournySelector
        let keepsake = db.fetchKeepsake(id: keepsakeId)
        self.thumbnailImage  = keepsake
            .flatMap { MediaStorageManager.shared.loadThumbnail($0.thumbnailFileName) }
        
        self.lastWords       = keepsake?.lastWords.flatMap { $0.isEmpty ? nil : $0 } 
                               ?? Self.randomDefaultLastWords()
        self.keepsakeName    = keepsake?.name ?? ""
        self.cardDetailText  = Self.formatCardDetail(keepsake: keepsake)
    }

    private static func formatCardDetail(keepsake: Keepsake?) -> String {
        guard let keepsake else { return "" }
        
        var lines: [String] = []

        // PartialDate 기반 날짜 섹션
        let acquired = PartialDate(
            year: keepsake.acquiredYear,
            month: keepsake.acquiredMonth,
            day: keepsake.acquiredDay
        )
        let disposal = PartialDate(
            year: keepsake.disposalYear,
            month: keepsake.disposalMonth,
            day: keepsake.disposalDay
        )

        // 하위 호환성 (acquiredYear가 0인데 acquiredDate가 있는 경우)
        let finalAcquired = (acquired.year == 0 && keepsake.acquiredDate != nil)
            ? PartialDate(
                year: Calendar.current.component(.year, from: keepsake.acquiredDate!),
                month: Calendar.current.component(.month, from: keepsake.acquiredDate!),
                day: Calendar.current.component(.day, from: keepsake.acquiredDate!)
              )
            : acquired

        let finalDisposal = (disposal.year == 0 && keepsake.disposalDate != .distantFuture)
            ? PartialDate(
                year: Calendar.current.component(.year, from: keepsake.disposalDate),
                month: Calendar.current.component(.month, from: keepsake.disposalDate),
                day: Calendar.current.component(.day, from: keepsake.disposalDate)
              )
            : disposal

        let duration = PartialDate.approximateDuration(from: finalAcquired, to: finalDisposal)
                       ?? NSLocalizedString("ritual.cardDetail.defaultDuration", comment: "")
        let ability = keepsake.ability.flatMap { $0.isEmpty ? nil : $0 }
                      ?? NSLocalizedString("keepsake.defaultAbility", comment: "함께 하기")
        let abilityStr = String(format: NSLocalizedString("ritual.cardDetail.ability", comment: ""), ability, eulReul(ability))
        lines.append("\(duration) \(abilityStr)")

        lines.append("")   // 빈 줄
        lines.append(String(format: NSLocalizedString("ritual.cardDetail.restingDate", comment: ""), VSDateFormatter.dot.string(from: Date())))

        return lines.joined(separator: "\n")
    }

    private static func eulReul(_ word: String) -> String {
        guard let last = word.unicodeScalars.last,
              last.value >= 0xAC00, last.value <= 0xD7A3 else { return "을/를 " }
        return (last.value - 0xAC00) % 28 == 0 ? "를 " : "을 "
    }

    // MARK: - Transform

    func transform(input: Input) -> Output {
        // nextTap 이후 imageTap 무시
        let liveImageTap = input.imageTap.take(until: input.nextTap)

        let tapCount = liveImageTap
            .scan(0) { count, _ in count + 1 }
            .share(replay: 1)

        let mournySpawn = tapCount
            .map { [mournySelector] count -> MournySpawn in
                MournySpawn(
                    event: mournySelector(),
                    scale: Self.scale(for: count)
                )
            }

        let scaleDidChange = tapCount
            .map { Self.scale(for: $0) }
            .distinctUntilChanged()
            .skip(1)

        let showNextButton = tapCount
            .map { $0 >= 1 }
            .distinctUntilChanged()

        let nextTapCount = input.nextTap
            .scan(0) { c, _ in c + 1 }
            .share(replay: 1)

        let enterDonePhase   = nextTapCount.filter { $0 == 1 }.map { _ in () }
        let enterCardPhase   = nextTapCount.filter { $0 == 2 }.map { _ in () }
        let navigateToDetail = nextTapCount.filter { $0 == 3 }.map { _ in () }

        // mournyCount DB 저장 — 1차 탭 시
        enterDonePhase
            .withLatestFrom(tapCount)
            .subscribe(onNext: { [weak self] count in
                guard let self,
                      let keepsake = self.db.fetchKeepsake(id: self.keepsakeId) else { return }
                try? self.db.updateKeepsake(keepsake) { $0.mournyCount += count }
            })
            .disposed(by: disposeBag)

        return Output(
            mournySpawn:      mournySpawn,
            scaleDidChange:   scaleDidChange,
            showNextButton:   showNextButton,
            enterDonePhase:   enterDonePhase,
            enterCardPhase:   enterCardPhase,
            navigateToDetail: navigateToDetail
        )
    }

    // MARK: - Scale Logic

    /// 4^n 단위 경계마다 0.15씩 감소, 최소 0.4
    /// 0~2 → 1.00 / 3~8 → 0.85 / 9~26 → 0.70 / 27~80 → 0.55 / 81+ → 0.40
    static func scale(for tapCount: Int) -> CGFloat {
        var threshold = 4
        var level = 0
        while tapCount >= threshold {
            level += 1
            threshold *= 4
        }
        return max(0.4, 1.0 - CGFloat(level) * 0.15)
    }
}
