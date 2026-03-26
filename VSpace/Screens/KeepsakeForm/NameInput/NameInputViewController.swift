//
//  NameInputViewController.swift
//  VSpace
//

import UIKit
import RxSwift
import RxCocoa

final class NameInputViewController: BaseViewController {

    // MARK: - Properties

    private weak var coordinator: HomeCoordinator?
    private let viewModel: NameInputViewModel
    private let contentView = NameInputView()

    // MARK: - Init

    init(coordinator: HomeCoordinator, viewModel: NameInputViewModel) {
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
        let saved = viewModel.initialName
        if !saved.isEmpty { contentView.nameTextField.setText(saved) }
        bindViewModel()
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
