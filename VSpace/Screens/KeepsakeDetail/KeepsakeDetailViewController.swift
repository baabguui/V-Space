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
    private let deleteTapSubject = PublishSubject<Void>()

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
        contentView.setLastWords(viewModel.lastWords)
        contentView.frontRitualDateLabel.text = viewModel.ritualDateText
        contentView.abilityMemoryLabel.text   = viewModel.abilityDetailText
        contentView.memoryNoteLabel.text      = viewModel.memoryNote
        contentView.memoryNoteScrollView.isHidden = viewModel.memoryNote.isEmpty
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
            let closeButton = UIBarButtonItem(
                title: NSLocalizedString("keepsakeDetail.button.close", comment: ""),
                style: .plain,
                target: nil,
                action: nil
            )
            closeButton.setTitleTextAttributes(
                [.font: UIFont.pretendard(.semibold, size: 22)],
                for: .normal
            )
            navigationItem.leftBarButtonItem = closeButton
        }

        let deleteAction = UIAction(
            title: NSLocalizedString("keepsakeDetail.menu.delete", comment: "삭제하기"),
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.deleteTapSubject.onNext(())
        }
        let menu = UIMenu(children: [deleteAction])
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: menu)
        navigationItem.rightBarButtonItem = menuButton
    }

    private func bindViewModel() {
        let closeTap: Observable<Void>
        if viewModel.showsCloseButton, let btn = navigationItem.leftBarButtonItem {
            closeTap = btn.rx.tap.asObservable()
        } else {
            closeTap = .never()
        }

        let output = viewModel.transform(input: .init(
            closeTap:  closeTap,
            deleteTap: deleteTapSubject.asObservable()
        ))

        output.navigateDone
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.coordinator?.finish()
            })
            .disposed(by: disposeBag)

        output.showDeleteAlert
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.showDeleteConfirmAlert()
            })
            .disposed(by: disposeBag)
    }

    /// 삭제 확인 알럿을 표시합니다. 확인 시 파일과 Realm 데이터를 모두 삭제하고 홈으로 이동합니다
    private func showDeleteConfirmAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("keepsakeDetail.alert.delete.title", comment: "삭제하기"),
            message: NSLocalizedString("keepsakeDetail.alert.delete.message", comment: "데이터를 영구적으로 삭제합니다. 이 작업은 되돌릴 수 없습니다."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.cancel", comment: "취소"),
            style: .cancel
        ))
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("keepsakeDetail.menu.delete", comment: "삭제하기"),
            style: .destructive
        ) { [weak self] _ in
            self?.coordinator?.deleteAndFinish()
        })
        present(alert, animated: true)
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
}
