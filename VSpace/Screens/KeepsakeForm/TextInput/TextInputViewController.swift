//
//  TextInputViewController.swift
//  VSpace
//
//  기능 / 일화 / 마지막 말 공유 ViewController
//

import UIKit
import RxSwift
import RxCocoa
import RxRelay

final class TextInputViewController: BaseViewController {

    // MARK: - Properties

    private weak var coordinator: KeepsakeFormCoordinating?
    private let viewModel: TextInputViewModel
    private let config: TextInputConfig
    private lazy var contentView = TextInputView(config: config)
    private let confirmTapRelay = PublishRelay<Void>()

    // MARK: - Init

    init(coordinator: KeepsakeFormCoordinating, viewModel: TextInputViewModel, config: TextInputConfig) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        self.config = config
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
        populateInitialValue()
        setupActionButton()
        bindViewModel()
    }

    // MARK: - Setup

    private func populateInitialValue() {
        let saved = viewModel.initialText
        guard !saved.isEmpty else { return }
        if let tf = contentView.inputField as? VTextField {
            tf.setText(saved)
        } else if let mtf = contentView.inputField as? VMultilineTextField {
            mtf.setText(saved)
        }
    }

    private func setupActionButton() {
        if config == .lastWords {
            contentView.actionButton.rx.tap
                .subscribe(onNext: { [weak self] in self?.showCompletionAlert() })
                .disposed(by: disposeBag)
        } else {
            contentView.actionButton.rx.tap
                .bind(to: confirmTapRelay)
                .disposed(by: disposeBag)
        }
    }

    private func showCompletionAlert() {
        showAlert(
            title: NSLocalizedString("text_input.lastwords.alert.title", comment: ""),
            message: NSLocalizedString("text_input.lastwords.alert.message", comment: ""),
            confirmTitle: NSLocalizedString("form.button.complete", comment: ""),
            confirmStyle: .default,
            cancelTitle: NSLocalizedString("alert.default.cancel", comment: ""),
            onConfirm: { [weak self] in self?.confirmTapRelay.accept(()) }
        )
    }

    // MARK: - Binding

    private func bindViewModel() {
        let rxText: Observable<String>
        if let tf = contentView.inputField as? VTextField {
            rxText = tf.rxText
        } else if let mtf = contentView.inputField as? VMultilineTextField {
            rxText = mtf.rxText
        } else {
            rxText = .just("")
        }

        let input = TextInputViewModel.Input(
            text:    rxText,
            nextTap: confirmTapRelay.asObservable(),
            skipTap: contentView.skipButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)

        output.navigateNext
            .subscribe(onNext: { [weak self] keepsakeId in
                guard let self else { return }
                switch self.config {
                case .ability:    self.coordinator?.showMemoryNote(keepsakeId: keepsakeId)
                case .memoryNote: self.coordinator?.showLastWords(keepsakeId: keepsakeId)
                case .lastWords:  self.coordinator?.finishForm()
                }
            })
            .disposed(by: disposeBag)

        output.navigateSkip
            .subscribe(onNext: { [weak self] keepsakeId in
                guard let self else { return }
                switch self.config {
                case .ability:    self.coordinator?.showMemoryNote(keepsakeId: keepsakeId)
                case .memoryNote: self.coordinator?.showLastWords(keepsakeId: keepsakeId)
                case .lastWords:  self.coordinator?.finishForm()
                }
            })
            .disposed(by: disposeBag)
    }
}
