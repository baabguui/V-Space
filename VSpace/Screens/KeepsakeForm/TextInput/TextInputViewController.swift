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
        contentView.setThumbnail(viewModel.thumbnailImage)
        setupMoreButton()
        setupActionButton()
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
                case .lastWords:  self.coordinator?.showFormCompletion(keepsakeId: keepsakeId)
                }
            })
            .disposed(by: disposeBag)

        output.navigateSkip
            .subscribe(onNext: { [weak self] keepsakeId in
                guard let self else { return }
                switch self.config {
                case .ability:    self.coordinator?.showMemoryNote(keepsakeId: keepsakeId)
                case .memoryNote: self.coordinator?.showLastWords(keepsakeId: keepsakeId)
                case .lastWords:  self.coordinator?.showFormCompletion(keepsakeId: keepsakeId)
                }
            })
            .disposed(by: disposeBag)
    }
}
