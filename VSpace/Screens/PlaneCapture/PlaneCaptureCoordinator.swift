import UIKit
import RealmSwift
import RxSwift

final class PlaneCaptureCoordinator: Coordinator, PlaneCaptureCoordinating {

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    var onComplete: ((ObjectId) -> Void)?

    private let disposeBag = DisposeBag()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let vc = PlaneCaptureViewController(coordinator: self)
        navigationController.pushViewController(vc, animated: true)
    }

    func showImagePicker(from viewController: UIViewController, completion: @escaping (UIImage, UIImage) -> Void) {
        let pickerVC = ImagePickerViewController()
        let nav = UINavigationController(rootViewController: pickerVC)
        nav.modalPresentationStyle = .fullScreen
        var cropBag = DisposeBag()

        pickerVC.imageSelected
            .subscribe(onNext: { [weak nav] originalImage in
                guard let nav else { return }
                cropBag = DisposeBag()

                if nav.viewControllers.count > 1 {
                    nav.popViewController(animated: false)
                }

                let cropVC = CircularCropViewController(image: originalImage)
                cropVC.cropConfirmed
                    .take(1)
                    .subscribe(onNext: { [weak nav] croppedImage in
                        completion(originalImage, croppedImage)
                        nav?.dismiss(animated: true)
                    })
                    .disposed(by: cropBag)
                nav.pushViewController(cropVC, animated: true)
            })
            .disposed(by: disposeBag)

        viewController.present(nav, animated: true)
    }

    func finishCapture(keepsakeId: ObjectId) {
        onComplete?(keepsakeId)
    }
}
