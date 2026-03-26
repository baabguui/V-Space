import UIKit
import RealmSwift

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

    func showNameInput(keepsakeId: ObjectId) {
        let vc = NameInputViewController(
            coordinator: self,
            viewModel: NameInputViewModel(keepsakeId: keepsakeId)
        )
        navigationController.pushViewController(vc, animated: true)
    }

    func showAcquiredDate(keepsakeId: ObjectId) {
        let vc = DateInputViewController(
            coordinator: self,
            viewModel: DateInputViewModel(keepsakeId: keepsakeId, config: .acquiredDate),
            config: .acquiredDate
        )
        navigationController.pushViewController(vc, animated: true)
    }

    func showDisposalDate(keepsakeId: ObjectId) {
        let vc = DateInputViewController(
            coordinator: self,
            viewModel: DateInputViewModel(keepsakeId: keepsakeId, config: .disposalDate),
            config: .disposalDate
        )
        navigationController.pushViewController(vc, animated: true)
    }

    func showAbility(keepsakeId: ObjectId) {
        let vc = TextInputViewController(
            coordinator: self,
            viewModel: TextInputViewModel(keepsakeId: keepsakeId, config: .ability),
            config: .ability
        )
        navigationController.pushViewController(vc, animated: true)
    }

    func showMemoryNote(keepsakeId: ObjectId) {
        let vc = TextInputViewController(
            coordinator: self,
            viewModel: TextInputViewModel(keepsakeId: keepsakeId, config: .memoryNote),
            config: .memoryNote
        )
        navigationController.pushViewController(vc, animated: true)
    }

    func showLastWords(keepsakeId: ObjectId) {
        let vc = TextInputViewController(
            coordinator: self,
            viewModel: TextInputViewModel(keepsakeId: keepsakeId, config: .lastWords),
            config: .lastWords
        )
        navigationController.pushViewController(vc, animated: true)
    }

    func finishKeepsakeForm() {
        navigationController.popToRootViewController(animated: true)
    }

    func resumeKeepsakeForm(keepsake: Keepsake) {
        let id = keepsake.id
        switch keepsake.progressStep ?? 1 {
        case 1:  showNameInput(keepsakeId: id)
        case 2:  showAcquiredDate(keepsakeId: id)
        case 3:  showDisposalDate(keepsakeId: id)
        case 4:  showAbility(keepsakeId: id)
        case 5:  showMemoryNote(keepsakeId: id)
        case 6:  showLastWords(keepsakeId: id)
        default: break
        }
    }

    func popCaptureSession() {
        navigationController.popViewController(animated: true)
    }
}
