import UIKit
import RealmSwift
import RxSwift

final class PlaneCaptureCoordinator: Coordinator, PlaneCaptureCoordinating {

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    var onComplete: ((ObjectId) -> Void)?

    private let db: KeepsakeDatabaseManaging
    private let storage: MediaStorageManaging
    private let disposeBag = DisposeBag()
    private var pendingKeepsakeId: ObjectId?

    init(
        navigationController: UINavigationController,
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager(),
        storage: MediaStorageManaging = MediaStorageManager.shared
    ) {
        self.navigationController = navigationController
        self.db = db
        self.storage = storage
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
                    .subscribe(onNext: { [weak self, weak nav] croppedImage in
                        guard let self else { return }
                        if self.saveKeepsake(original: originalImage, cropped: croppedImage) {
                            completion(originalImage, croppedImage)
                        }
                        nav?.dismiss(animated: true)
                    })
                    .disposed(by: cropBag)
                nav.pushViewController(cropVC, animated: true)
            })
            .disposed(by: disposeBag)

        viewController.present(nav, animated: true)
    }

    /// 이미지 확정 시점에 파일 저장 + Realm 저장을 수행합니다.
    /// 재선택 시 기존 레코드를 먼저 정리합니다.
    /// - Returns: 저장 성공 여부
    @discardableResult
    private func saveKeepsake(original: UIImage, cropped: UIImage) -> Bool {
        // 재선택: 이전 파일 + Realm 레코드 정리
        if let previousId = pendingKeepsakeId,
           let previous = db.fetchKeepsake(id: previousId) {
            storage.deleteKeepsakeFiles(
                resourceFileName: previous.resourceFileName,
                thumbnailFileName: previous.thumbnailFileName,
                recordType: previous.recordType
            )
            try? db.deleteKeepsake(previous)
        }
        pendingKeepsakeId = nil

        do {
            let photoFileName = try storage.savePhoto(original)
            let thumbFileName = try storage.saveThumbnail(cropped)
            let keepsake = Keepsake()
            keepsake.resourceFileName = photoFileName
            keepsake.thumbnailFileName = thumbFileName
            keepsake.recordType = .photo
            keepsake.disposalDate = .distantFuture
            keepsake.status = .inProgress
            keepsake.progressStep = 1
            try db.saveKeepsake(keepsake)
            pendingKeepsakeId = keepsake.id
            return true
        } catch {
            let alert = UIAlertController(
                title: NSLocalizedString("error.title", comment: ""),
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("alert.default.confirm", comment: ""),
                style: .default
            ))
            navigationController.present(alert, animated: true)
            return false
        }
    }

    func finishCapture() {
        guard let keepsakeId = pendingKeepsakeId else { return }
        onComplete?(keepsakeId)
    }
}
