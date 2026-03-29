import UIKit
import RealmSwift

final class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    private let window: UIWindow
    private weak var homeCoordinator: HomeCoordinator?

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.navigationController.navigationBar.tintColor = .vsPrimary
    }

    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        showHome()
    }

    func handleNotificationTap(keepsakeId: String) {
        guard let id = try? ObjectId(string: keepsakeId),
              let keepsake = KeepsakeDatabaseManager().fetchKeepsake(id: id) else { return }
        navigationController.popToRootViewController(animated: false)
        homeCoordinator?.showKeepsakeStatus(keepsake: keepsake)
    }

    private func showHome() {
        let coordinator = HomeCoordinator(navigationController: navigationController)
        homeCoordinator = coordinator
        childCoordinators.append(coordinator)
        coordinator.start()
    }
}
