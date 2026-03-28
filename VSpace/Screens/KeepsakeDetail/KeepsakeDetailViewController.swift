//
//  KeepsakeDetailViewController.swift
//  VSpace
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class KeepsakeDetailViewController: BaseViewController {

    // MARK: - Properties

    private weak var coordinator: KeepsakeDetailCoordinating?
    private let viewModel: KeepsakeDetailViewModel
    private lazy var contentView = KeepsakeDetailView()

    private var isShowingBack = false
    private var isFlipping    = false

    // MARK: - Init

    init(coordinator: KeepsakeDetailCoordinating, viewModel: KeepsakeDetailViewModel) {
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
        contentView.thumbnailImageView.image  = viewModel.thumbnailImage
        contentView.nameLabel.text            = viewModel.keepsakeName
        contentView.dateRangeLabel.text       = viewModel.dateRangeText
        contentView.lastWordsLabel.text       = viewModel.lastWords
        contentView.frontRitualDateLabel.text = viewModel.ritualDateText
        contentView.abilityMemoryLabel.text   = buildAbilityMemoryText()
        contentView.mournyCountLabel.text     = viewModel.mournyCountText
        contentView.backRitualDateLabel.text  = viewModel.ritualDateText

        viewModel.mournyImageNames.forEach { name in
            let iv = UIImageView(image: UIImage(named: name))
            iv.contentMode = .scaleAspectFit
            iv.snp.makeConstraints { $0.size.equalTo(50) }
            contentView.mournyRowStackView.addArrangedSubview(iv)
        }

        let hasMourny = !viewModel.mournyImageNames.isEmpty
        contentView.mournyCountLabel.isHidden   = !hasMourny
        contentView.mournyRowStackView.isHidden = !hasMourny

        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        bindViewModel()
        setupPanGesture()
        setupThumbnailTapGesture()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        if viewModel.showsCloseButton {
            navigationItem.hidesBackButton = true
            let closeButton = UIBarButtonItem(title: NSLocalizedString("keepsakeDetail.button.close", comment: ""), style: .plain, target: nil, action: nil)
            closeButton.setTitleTextAttributes(
                [.font: UIFont.pretendard(.semibold, size: 22)],
                for: .normal
            )
            navigationItem.rightBarButtonItem = closeButton
        }
    }

    private func bindViewModel() {
        let closeTap: Observable<Void>
        if viewModel.showsCloseButton, let btn = navigationItem.rightBarButtonItem {
            closeTap = btn.rx.tap.asObservable()
        } else {
            closeTap = .never()
        }

        let output = viewModel.transform(input: .init(closeTap: closeTap))
        output.navigateDone
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.coordinator?.finish()
            })
            .disposed(by: disposeBag)
    }

    private func setupPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        contentView.addGestureRecognizer(pan)
    }

    private func setupThumbnailTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleThumbnailTap))
        contentView.thumbnailImageView.isUserInteractionEnabled = true
        contentView.thumbnailImageView.addGestureRecognizer(tap)
    }

    // MARK: - Flip

    private func flip(fromLeft: Bool) {
        guard !isFlipping else { return }
        isFlipping = true

        let option: UIView.AnimationOptions = fromLeft ? .transitionFlipFromLeft : .transitionFlipFromRight
        let toBack = !isShowingBack

        UIView.transition(
            with: contentView.cardSceneView,
            duration: 0.5,
            options: [option, .allowUserInteraction]
        ) {
            self.contentView.frontCardView.isHidden = toBack
            self.contentView.backCardView.isHidden  = !toBack
        } completion: { _ in
            self.isShowingBack = toBack
            self.isFlipping    = false
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .ended || gesture.state == .cancelled else { return }

        let tx = gesture.translation(in: view).x
        let vx = gesture.velocity(in: view).x

        let shouldFlip = abs(tx) > view.bounds.width * 0.2 || abs(vx) > 300
        guard shouldFlip else { return }

        // tx > 0 (오른쪽 스와이프) → fromLeft, tx < 0 (왼쪽 스와이프) → fromRight
        flip(fromLeft: tx > 0)
    }

    // MARK: - Thumbnail Tap

    @objc private func handleThumbnailTap() {
        switch viewModel.recordType {
        case .photo:
            guard let image = viewModel.originalImage else { return }
            coordinator?.showPhotoViewer(image: image)
        case .threeD:
            guard let url = viewModel.modelURL else { return }
            coordinator?.showModelViewer(modelURL: url)
        case .fragment:
            break
        }
    }

    // MARK: - Helpers

    private func buildAbilityMemoryText() -> String {
        [viewModel.ability, viewModel.memoryNote]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
}
