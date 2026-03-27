import UIKit
import RealmSwift

final class KeepsakeFormCoordinator: Coordinator, KeepsakeFormCoordinating {

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    var onFinish: (() -> Void)?

    private let keepsakeId: ObjectId
    private let startStep: Int

    init(navigationController: UINavigationController, keepsakeId: ObjectId, startStep: Int = 1) {
        self.navigationController = navigationController
        self.keepsakeId = keepsakeId
        self.startStep = startStep
    }

    func start() {
        switch startStep {
        case 2: showAcquiredDate(keepsakeId: keepsakeId)
        case 3: showDisposalDate(keepsakeId: keepsakeId)
        case 4: showAbility(keepsakeId: keepsakeId)
        case 5: showMemoryNote(keepsakeId: keepsakeId)
        case 6: showLastWords(keepsakeId: keepsakeId)
        default: showNameInput(keepsakeId: keepsakeId)
        }
    }

    private func showNameInput(keepsakeId: ObjectId) {
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

    func showFormCompletion(keepsakeId: ObjectId) {
        let vc = FormCompletionViewController(
            coordinator: self,
            viewModel: FormCompletionViewModel(keepsakeId: keepsakeId)
        )
        navigationController.pushViewController(vc, animated: true)
    }

    func finishForm() {
        onFinish?()
        navigationController.popToRootViewController(animated: true)
    }
}
