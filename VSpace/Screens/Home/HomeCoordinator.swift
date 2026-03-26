import UIKit
import RealmSwift

final class HomeCoordinator: Coordinator, HomeCoordinating {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let vc = HomeViewController(coordinator: self, viewModel: HomeViewModel())
        navigationController.pushViewController(vc, animated: true)
    }

    func showCaptureTypeSelect() {
        let vc = CaptureTypeSelectViewController(coordinator: self)
        navigationController.pushViewController(vc, animated: true)
    }

    func showPlaneCapture() {
        let coordinator = PlaneCaptureCoordinator(navigationController: navigationController)
        coordinator.onComplete = { [weak self, weak coordinator] keepsakeId in
            guard let self, let coordinator else { return }
            self.removeChildCoordinator(coordinator)
            self.startKeepsakeForm(keepsakeId: keepsakeId)
        }
        childCoordinators.append(coordinator)
        coordinator.start()
    }

    func showObjectCapture() {
        guard #available(iOS 17.0, *) else { return }
        let coordinator = ObjectCaptureCoordinator(navigationController: navigationController)
        coordinator.onComplete = { [weak self, weak coordinator] keepsakeId in
            guard let self, let coordinator else { return }
            self.removeChildCoordinator(coordinator)
            self.startKeepsakeForm(keepsakeId: keepsakeId)
        }
        childCoordinators.append(coordinator)
        coordinator.start()
    }

    func resumeKeepsakeForm(keepsake: Keepsake) {
        startKeepsakeForm(keepsakeId: keepsake.id, startStep: keepsake.progressStep ?? 1)
    }

    private func startKeepsakeForm(keepsakeId: ObjectId, startStep: Int = 1) {
        let coordinator = KeepsakeFormCoordinator(
            navigationController: navigationController,
            keepsakeId: keepsakeId,
            startStep: startStep
        )
        coordinator.onFinish = { [weak self, weak coordinator] in
            guard let coordinator else { return }
            self?.removeChildCoordinator(coordinator)
        }
        childCoordinators.append(coordinator)
        coordinator.start()
    }
}
