import UIKit

final class HomeCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewModel = HomeViewModel()
        let viewController = HomeViewController(viewModel: viewModel)
        viewController.coordinator = self
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func showCaptureTypeSelect() {
        let viewController = CaptureTypeSelectViewController()
        viewController.coordinator = self
        navigationController.pushViewController(viewController, animated: true)
    }

    func showCaptureSession() {
        if #available(iOS 17.0, *) {
            let captureVC = CaptureViewController()
            navigationController.pushViewController(captureVC, animated: true)
        } else {
            // 알럿 로직은 VC에서 처리하거나 Coordinator에서 공통 유틸로 처리 가능
        }
    }
}
