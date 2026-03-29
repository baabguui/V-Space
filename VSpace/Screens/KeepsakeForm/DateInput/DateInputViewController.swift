//
//  DateInputViewController.swift
//  VSpace
//
//  처음 만난 날 / 보내주는 날 공유 ViewController
//

import UIKit
import RxSwift
import RxCocoa

final class DateInputViewController: BaseViewController {

    // MARK: - Properties

    private weak var coordinator: KeepsakeFormCoordinating?
    private let viewModel: DateInputViewModel
    private let config: DateInputConfig
    private let showsMoreButton: Bool
    private lazy var contentView = DateInputView(config: config)

    // MARK: - Init

    init(
        coordinator: KeepsakeFormCoordinating,
        viewModel: DateInputViewModel,
        config: DateInputConfig,
        showsMoreButton: Bool = true
    ) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        self.config = config
        self.showsMoreButton = showsMoreButton
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.setInitialDate(viewModel.initialDate)
        contentView.setThumbnail(viewModel.thumbnailImage)
        if showsMoreButton { setupMoreButton() }
        bindViewModel()
    }

    // MARK: - Navigation Bar

    private func setupMoreButton() {
        let saveAction = UIAction(
            title: NSLocalizedString("form.menu.saveAndExit", comment: ""),
            image: UIImage(systemName: "square.and.arrow.down")
        ) { [weak self] _ in self?.showSaveAndExitAlert() }

        let deleteAction = UIAction(
            title: NSLocalizedString("form.menu.delete", comment: ""),
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { [weak self] _ in self?.showDeleteAlert() }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            menu: UIMenu(children: [saveAction, deleteAction])
        )
    }

    private func showSaveAndExitAlert() {
        showAlert(
            title: NSLocalizedString("form.menu.saveAndExit.alert.title", comment: ""),
            message: NSLocalizedString("form.menu.saveAndExit.alert.message", comment: ""),
            confirmTitle: NSLocalizedString("form.menu.saveAndExit", comment: ""),
            confirmStyle: .default,
            cancelTitle: NSLocalizedString("alert.default.cancel", comment: ""),
            onConfirm: { [weak self] in self?.coordinator?.saveAndExit() }
        )
    }

    private func showDeleteAlert() {
        showAlert(
            title: NSLocalizedString("form.menu.delete.alert.title", comment: ""),
            message: NSLocalizedString("form.menu.delete.alert.message", comment: ""),
            confirmTitle: NSLocalizedString("form.menu.delete", comment: ""),
            confirmStyle: .destructive,
            cancelTitle: NSLocalizedString("alert.default.cancel", comment: ""),
            onConfirm: { [weak self] in self?.coordinator?.deleteKeepsake() }
        )
    }

    // MARK: - Binding

    private func bindViewModel() {
        let input = DateInputViewModel.Input(
            date:    contentView.selectedDateRelay.asObservable(),
            nextTap: contentView.nextButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)

        output.navigateNext
            .subscribe(onNext: { [weak self] keepsakeId in
                guard let self else { return }
                switch self.config {
                case .acquiredDate: self.coordinator?.showDisposalDate(keepsakeId: keepsakeId)
                case .disposalDate: self.coordinator?.showAbility(keepsakeId: keepsakeId)
                }
            })
            .disposed(by: disposeBag)
    }
}
