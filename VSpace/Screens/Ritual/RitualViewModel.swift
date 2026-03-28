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
    }

    struct Output {
        let mournySpawn:    Observable<MournySpawn>
        let scaleDidChange: Observable<CGFloat>
    }

    // MARK: - Properties

    let thumbnailImage: UIImage?

    private let mournySelector: MournyEventSelector

    // MARK: - Init

    init(
        keepsakeId: ObjectId,
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager(),
        mournySelector: @escaping MournyEventSelector = MournyEvent.random
    ) {
        self.mournySelector = mournySelector
        self.thumbnailImage = db.fetchKeepsake(id: keepsakeId)
            .flatMap { MediaStorageManager.shared.loadThumbnail($0.thumbnailFileName) }
    }

    // MARK: - Transform

    func transform(input: Input) -> Output {
        let tapCount = input.imageTap
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

        return Output(mournySpawn: mournySpawn, scaleDidChange: scaleDidChange)
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
