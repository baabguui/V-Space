//
//  RitualViewController.swift
//  VSpace
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class RitualViewController: BaseViewController {

    // MARK: - Constants

    private enum Layout {
        static let mournySize: CGFloat    = 80
        static let landingOffset: CGFloat = 20   // 1링 시작 여백 (radius 바깥)
        static let landingStep: CGFloat   = 55   // 링 간격 (혼잡 시 바깥으로 이동)
        static let maxRings: Int          = 5    // 최대 링 수
        static let minSpacing: CGFloat    = 55   // 착지점 간 최소 거리
        static let entryMargin: CGFloat   = 60   // 화면 밖 시작 여백
        static let randomJitter: CGFloat  = 40   // 진입 X/Y 흔들림 범위
        static let angleJitter: CGFloat   = 0.7  // 착지 각도 흔들림 (rad)
    }

    // MARK: - Properties

    private weak var coordinator: RitualCoordinating?
    private let viewModel: RitualViewModel
    private lazy var contentView = RitualView()

    private var mournyViews: [UIImageView] = []
    private var landingPoints: [CGPoint]   = []

    // MARK: - Init

    init(coordinator: RitualCoordinating, viewModel: RitualViewModel) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    // MARK: - Lifecycle

    override func loadView() {
        contentView.thumbnailImageView.image = viewModel.thumbnailImage
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }

    // MARK: - Binding

    private func bindViewModel() {
        let input = RitualViewModel.Input(
            imageTap: contentView.imageTap,
            nextTap:  contentView.nextButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)

        // 순서 중요: mournySpawn 먼저 구독해 scaleDidChange 시점에 새 뷰가 mournyViews에 포함되도록 함
        output.mournySpawn
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] spawn in
                self?.spawnMourny(spawn)
            })
            .disposed(by: disposeBag)

        output.scaleDidChange
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] scale in
                self?.animateScaleChange(to: scale)
            })
            .disposed(by: disposeBag)

        output.showNextButton
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] show in
                self?.contentView.nextButton.isHidden = !show
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Mourny Spawn

    private func spawnMourny(_ spawn: MournySpawn) {
        let image = UIImage(named: spawn.event.name)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        imageView.frame = CGRect(x: 0, y: 0, width: Layout.mournySize, height: Layout.mournySize)

        // 오른쪽에서 진입하는 horizontal은 좌우 반전
        let isFlipped: Bool
        if case .horizontal(let fromLeft) = spawn.event.direction { isFlipped = !fromLeft }
        else { isFlipped = false }
        let scaleX: CGFloat = isFlipped ? -spawn.scale : spawn.scale
        imageView.transform = CGAffineTransform(scaleX: scaleX, y: spawn.scale)

        let (start, landing) = makeEntry(for: spawn.event, scale: spawn.scale)
        imageView.center = start

        view.addSubview(imageView)
        mournyViews.append(imageView)
        landingPoints.append(landing)

        UIView.animate(
            withDuration: 3.0,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0.1,
            options: []
        ) {
            imageView.center = landing
        } completion: { [weak imageView] _ in
            guard let imageView else { return }
            UIView.transition(
                with: imageView,
                duration: 0.2,
                options: .transitionCrossDissolve
            ) {
                imageView.image = UIImage(named: spawn.event.arriveName)
            }
        }
    }

    private func animateScaleChange(to scale: CGFloat) {
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0
        ) {
            self.mournyViews.forEach {
                let isFlipped = $0.transform.a < 0
                $0.transform = CGAffineTransform(scaleX: isFlipped ? -scale : scale, y: scale)
            }
        }
    }

    // MARK: - Entry Calculation

    private func makeEntry(for event: MournyEvent, scale: CGFloat) -> (start: CGPoint, landing: CGPoint) {
        let bounds = view.bounds
        let thumb  = contentView.thumbnailImageView.frame
        let center = CGPoint(x: thumb.midX, y: thumb.midY)
        let radius = thumb.width / 2

        switch event.direction {

        case .front:
            let start = CGPoint(
                x: center.x + CGFloat.random(in: -Layout.randomJitter...Layout.randomJitter),
                y: -Layout.entryMargin
            )
            return (start, bestLanding(center: center, radius: radius, baseAngle: -.pi / 2, scale: scale))

        case .back:
            let start = CGPoint(
                x: center.x + CGFloat.random(in: -Layout.randomJitter...Layout.randomJitter),
                y: bounds.height + Layout.entryMargin
            )
            return (start, bestLanding(center: center, radius: radius, baseAngle: .pi / 2, scale: scale))

        case .horizontal(let fromLeft):
            let start = CGPoint(
                x: fromLeft ? -Layout.entryMargin : bounds.width + Layout.entryMargin,
                y: center.y + CGFloat.random(in: -Layout.randomJitter...Layout.randomJitter)
            )
            let baseAngle: CGFloat = fromLeft ? .pi : 0
            return (start, bestLanding(center: center, radius: radius, baseAngle: baseAngle, scale: scale))
        }
    }

    /// 안쪽 링부터 균등 각도 스윕으로 빈 자리를 확실히 탐색.
    /// 랜덤 샘플링 대신 균등 분할로 각 링의 빈 자리를 놓치지 않음.
    /// 스케일이 작을수록 필요 간격이 줄어 이미 채워진 링에도 진입 가능.
    private func bestLanding(center: CGPoint, radius: CGFloat, baseAngle: CGFloat, scale: CGFloat) -> CGPoint {
        let effectiveSpacing = Layout.minSpacing * scale  // 스케일 비례 최소 간격
        let sweepCount = 36  // 각도 균등 분할 수 (해상도)

        for ring in 0..<Layout.maxRings {
            let dist = radius + Layout.landingOffset + CGFloat(ring) * Layout.landingStep
            // jitter 범위를 sweepCount 등분하여 균등하게 탐색
            let candidates = (0..<sweepCount).map { i -> CGPoint in
                let t = CGFloat(i) / CGFloat(sweepCount - 1)
                let angle = baseAngle + (-Layout.angleJitter + t * 2 * Layout.angleJitter)
                return landingPoint(center: center, distance: dist, angle: angle)
            }
            let valid = candidates.filter { distanceToNearest($0) >= effectiveSpacing }
            if let best = valid.max(by: { distanceToNearest($0) < distanceToNearest($1) }) {
                return best
            }
        }
        // 모든 링이 꽉 찬 경우 가장 바깥 링에서 최선 선택
        let dist = radius + Layout.landingOffset + CGFloat(Layout.maxRings - 1) * Layout.landingStep
        var best = landingPoint(center: center, distance: dist, angle: baseAngle)
        var bestDist = distanceToNearest(best)
        for i in 0..<sweepCount {
            let t = CGFloat(i) / CGFloat(sweepCount - 1)
            let angle = baseAngle + (-Layout.angleJitter + t * 2 * Layout.angleJitter)
            let candidate = landingPoint(center: center, distance: dist, angle: angle)
            let d = distanceToNearest(candidate)
            if d > bestDist { bestDist = d; best = candidate }
        }
        return best
    }

    private func distanceToNearest(_ point: CGPoint) -> CGFloat {
        landingPoints
            .map { hypot($0.x - point.x, $0.y - point.y) }
            .min() ?? .greatestFiniteMagnitude
    }

    private func landingPoint(center: CGPoint, distance: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + cos(angle) * distance,
            y: center.y + sin(angle) * distance
        )
    }
}
