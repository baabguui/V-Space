//
//  RitualCoordinator.swift
//  VSpace
//

import UIKit
import RealmSwift

final class RitualCoordinator: Coordinator, RitualCoordinating {

    // MARK: - Coordinator

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    // MARK: - Properties

    private let keepsakeId: ObjectId
    private let db: KeepsakeDatabaseManaging
    var onFinish: (() -> Void)?

    // MARK: - Init

    init(
        navigationController: UINavigationController,
        keepsakeId: ObjectId,
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager()
    ) {
        self.navigationController = navigationController
        self.keepsakeId = keepsakeId
        self.db = db
    }

    // MARK: - Coordinator

    func start() {
        let vc = KeepsakeStatusViewController(
            coordinator: self,
            viewModel: KeepsakeStatusViewModel(keepsakeId: keepsakeId)
        )
        navigationController.pushViewController(vc, animated: true)
    }

    // MARK: - RitualCoordinating

    func showRitual() {
        let vc = RitualViewController(
            coordinator: self,
            viewModel: RitualViewModel(keepsakeId: keepsakeId)
        )
        navigationController.pushViewController(vc, animated: true)
    }

    func showKeepsakeDetail() {
        let child = KeepsakeDetailCoordinator(
            navigationController: navigationController,
            keepsakeId: keepsakeId,
            db: db,
            mode: .completion
        )
        childCoordinators.append(child)
        child.onFinish = { [weak self, weak child] in
            guard let child else { return }
            self?.removeChildCoordinator(child)
            self?.onFinish?()
        }
        child.start()
    }
}
