//
//  FormCompletionViewController.swift
//  VSpace
//

import UIKit
import RxSwift
import RxCocoa

final class FormCompletionViewController: BaseViewController {

    // MARK: - Properties

    private weak var coordinator: KeepsakeFormCoordinating?
    private let viewModel: FormCompletionViewModel
    private lazy var contentView = KeepsakeActionView(secondaryStyle: viewModel.isAvailable ? .white : .accent)

    // MARK: - Init

    init(coordinator: KeepsakeFormCoordinating, viewModel: FormCompletionViewModel) {
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
        let isAvailable = viewModel.isAvailable
        let message: String
        let primaryTitle: String
        let secondaryTitle: String

        if isAvailable {
            message = NSLocalizedString("form_completion.available.message", comment: "")
            primaryTitle = NSLocalizedString("form_completion.start", comment: "")
            secondaryTitle = NSLocalizedString("form_completion.later", comment: "")
        } else {
            let format = NSLocalizedString("form_completion.unavailable.message", comment: "")
            message = String(format: format, viewModel.name)
            primaryTitle = NSLocalizedString("form_completion.go_home", comment: "")
            secondaryTitle = NSLocalizedString("form_completion.notify", comment: "")
        }

        contentView.configure(message: message, primaryTitle: primaryTitle, secondaryTitle: secondaryTitle)
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        bindViewModel()
    }

    // MARK: - Binding

    private func bindViewModel() {
        let input = FormCompletionViewModel.Input(
            primaryTap:   contentView.primaryButton.rx.tap.asObservable(),
            secondaryTap: contentView.secondaryButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)

        output.goHome
            .subscribe(onNext: { [weak self] in
                self?.coordinator?.finishForm()
            })
            .disposed(by: disposeBag)
    }
}
