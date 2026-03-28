//
//  KeepsakeDetailCoordinator.swift
//  VSpace
//

import UIKit
import RealmSwift

final class KeepsakeDetailCoordinator: Coordinator, KeepsakeDetailCoordinating {

    // MARK: - Mode

    enum Mode { case completion, readOnly }

    // MARK: - Coordinator

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    // MARK: - Properties

    private let keepsakeId: ObjectId
    private let db: KeepsakeDatabaseManaging
    private let mode: Mode
    var onFinish: (() -> Void)?

    // MARK: - Init

    init(
        navigationController: UINavigationController,
        keepsakeId: ObjectId,
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager(),
        mode: Mode
    ) {
        self.navigationController = navigationController
        self.keepsakeId = keepsakeId
        self.db = db
        self.mode = mode
    }

    // MARK: - Coordinator

    func start() {
        let viewModel = KeepsakeDetailViewModel(
            keepsakeId: keepsakeId,
            db: db,
            showsCloseButton: mode == .completion
        )
        let vc = KeepsakeDetailViewController(coordinator: self, viewModel: viewModel)
        navigationController.pushViewController(vc, animated: true)
    }

    // MARK: - KeepsakeDetailCoordinating

    func finish() {
        switch mode {
        case .completion:
            guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return }
            try? db.updateKeepsake(keepsake) {
                $0.status = .done
                if $0.ritualDate == nil { $0.ritualDate = Date() }
            }
            navigationController.popToRootViewController(animated: true)
        case .readOnly:
            navigationController.popViewController(animated: true)
        }
        onFinish?()
    }
}
