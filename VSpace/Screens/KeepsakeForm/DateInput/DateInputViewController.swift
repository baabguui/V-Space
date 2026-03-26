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
    private lazy var contentView = DateInputView(config: config)

    // MARK: - Init

    init(coordinator: KeepsakeFormCoordinating, viewModel: DateInputViewModel, config: DateInputConfig) {
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
        contentView.setInitialDate(viewModel.initialDate)
        bindViewModel()
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
