//
//  KeepsakeStatusViewController.swift
//  VSpace
//

import UIKit
import RxSwift
import RxCocoa

final class KeepsakeStatusViewController: BaseViewController {

    // MARK: - Properties

    private weak var coordinator: HomeCoordinating?
    private let viewModel: KeepsakeStatusViewModel
    private lazy var contentView = KeepsakeActionView()

    // MARK: - Init

    init(coordinator: HomeCoordinating, viewModel: KeepsakeStatusViewModel) {
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

        if isAvailable {
            message = NSLocalizedString("keepsake_status.available.message", comment: "")
            primaryTitle = NSLocalizedString("keepsake_status.confirm", comment: "")
        } else {
            message = NSLocalizedString("keepsake_status.unavailable.message", comment: "")
            primaryTitle = NSLocalizedString("keepsake_status.proceed_today", comment: "")
        }

        contentView.configure(
            message: message,
            primaryTitle: primaryTitle,
            secondaryTitle: NSLocalizedString("keepsake_status.change_date", comment: "")
        )
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }

    // MARK: - Binding

    private func bindViewModel() {
        let input = KeepsakeStatusViewModel.Input(
            primaryTap:   contentView.primaryButton.rx.tap.asObservable(),
            secondaryTap: contentView.secondaryButton.rx.tap.asObservable()
        )
        _ = viewModel.transform(input: input)
        // TODO: bind output when confirmRitual / changeDate are implemented
    }
}
