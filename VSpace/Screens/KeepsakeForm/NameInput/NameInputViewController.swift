//
//  NameInputViewController.swift
//  VSpace
//

import UIKit
import RxSwift
import RxCocoa

final class NameInputViewController: BaseViewController {

    // MARK: - Properties

    private weak var coordinator: KeepsakeFormCoordinating?
    private let viewModel: NameInputViewModel
    private let contentView = NameInputView()

    // MARK: - Init

    init(coordinator: KeepsakeFormCoordinating, viewModel: NameInputViewModel) {
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
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        setupMoreButton()
        contentView.setThumbnail(viewModel.thumbnailImage)
        let saved = viewModel.initialName
        if !saved.isEmpty { contentView.nameTextField.setText(saved) }
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
        let input = NameInputViewModel.Input(
            name: contentView.nameTextField.rxText,
            nextTap: contentView.nextButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)

        output.isNextEnabled
            .bind(to: contentView.nextButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.navigateNext
            .subscribe(onNext: { [weak self] keepsakeId in
                self?.coordinator?.showAcquiredDate(keepsakeId: keepsakeId)
            })
            .disposed(by: disposeBag)
    }
}
