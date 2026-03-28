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
    var onFinish: (() -> Void)?

    // MARK: - Init

    init(navigationController: UINavigationController, keepsakeId: ObjectId) {
        self.navigationController = navigationController
        self.keepsakeId = keepsakeId
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
}
