import UIKit

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get set }
    var childCoordinators: [Coordinator] { get set }
    func start()
}

extension Coordinator {
    func removeChildCoordinator(_ child: Coordinator) {
        childCoordinators = childCoordinators.filter { $0 !== child }
    }
}
