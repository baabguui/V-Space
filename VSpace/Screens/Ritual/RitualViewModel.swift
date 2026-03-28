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
        let mournySpawn:    Observable<MournySpawn>
        let scaleDidChange: Observable<CGFloat>
        let showNextButton: Observable<Bool>
        let enterDonePhase: Observable<Void>
        let enterCardPhase: Observable<Void>
    }

    // MARK: - Properties

    let thumbnailImage: UIImage?
    let lastWords: String?
    let keepsakeName: String
    let cardDetailText: String

    private let keepsakeId: ObjectId
    private let db: KeepsakeDatabaseManaging
    private let mournySelector: MournyEventSelector
    private let disposeBag = DisposeBag()

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
        self.lastWords       = keepsake?.lastWords
        self.keepsakeName    = keepsake?.name ?? ""
        self.cardDetailText  = Self.formatCardDetail(keepsake: keepsake)
    }

    private static func formatCardDetail(keepsake: Keepsake?) -> String {
        guard let keepsake else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"

        var lines: [String] = []

        let disposalStr  = formatter.string(from: keepsake.disposalDate)
        if let acquired  = keepsake.acquiredDate {
            let acquiredStr = formatter.string(from: acquired)
            lines.append("\(acquiredStr) - \(disposalStr) 동안")
        }

        if let ability = keepsake.ability, !ability.isEmpty {
            lines.append("\(ability) 을/를 해주다")
        }

        lines.append("")   // 빈 줄
        lines.append("\(formatter.string(from: Date())) 여기에 잠들다")

        return lines.joined(separator: "\n")
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

        let enterDonePhase = nextTapCount.filter { $0 == 1 }.map { _ in () }
        let enterCardPhase = nextTapCount.filter { $0 == 2 }.map { _ in () }

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
            mournySpawn:    mournySpawn,
            scaleDidChange: scaleDidChange,
            showNextButton: showNextButton,
            enterDonePhase: enterDonePhase,
            enterCardPhase: enterCardPhase
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
