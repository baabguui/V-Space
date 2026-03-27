import UIKit
import RealmSwift

@available(iOS 17.0, *)
final class ObjectCaptureCoordinator: Coordinator, ObjectCaptureCoordinating {

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    var onComplete: ((ObjectId) -> Void)?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let vc = CaptureViewController(coordinator: self)
        navigationController.pushViewController(vc, animated: true)
    }

    func showModelViewer(modelURL: URL, onSave: @escaping (UIImage) -> Void, onResume: @escaping () -> Void) {
        let vc = ModelViewerViewController(modelURL: modelURL, onSave: onSave, onResume: onResume)
        navigationController.pushViewController(vc, animated: true)
    }

    func finishCapture(keepsakeId: ObjectId) {
        onComplete?(keepsakeId)
    }

    func cancelCapture() {
        navigationController.popViewController(animated: true)
    }
}
