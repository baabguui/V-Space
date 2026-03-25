import UIKit

final class HomeCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewController = HomeViewController(coordinator: self, viewModel: HomeViewModel())
        navigationController.pushViewController(viewController, animated: true)
    }

    func showCaptureTypeSelect() {
        let viewController = CaptureTypeSelectViewController(coordinator: self)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showCaptureSession() {
        if #available(iOS 17.0, *) {
            let captureVC = CaptureViewController(coordinator: self)
            navigationController.pushViewController(captureVC, animated: true)
        } else {
            // 알럿 로직은 VC에서 처리하거나 Coordinator에서 공통 유틸로 처리 가능
        }
    }

    func showModelViewer(modelURL: URL, onSave: @escaping () -> Void, onResume: @escaping () -> Void) {
        let viewer = ModelViewerViewController(modelURL: modelURL, onSave: onSave, onResume: onResume)
        navigationController.pushViewController(viewer, animated: true)
    }

    func showSaveResult() {
        // TODO: 저장 완료 화면 연결 예정
    }

    func popCaptureSession() {
        navigationController.popViewController(animated: true)
    }
}
