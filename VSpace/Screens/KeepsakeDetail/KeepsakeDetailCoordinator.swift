//
//  KeepsakeDetailCoordinator.swift
//  VSpace
//

import UIKit
import RealmSwift

final class KeepsakeDetailCoordinator: Coordinator, KeepsakeDetailCoordinating {

    // MARK: - Mode

    enum Mode { case completion, readOnly }

    // MARK: - Coordinator

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    // MARK: - Properties

    private let keepsakeId: ObjectId
    private let db: KeepsakeDatabaseManaging
    private let mode: Mode
    var onFinish: (() -> Void)?

    // MARK: - Init

    init(
        navigationController: UINavigationController,
        keepsakeId: ObjectId,
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager(),
        mode: Mode
    ) {
        self.navigationController = navigationController
        self.keepsakeId = keepsakeId
        self.db = db
        self.mode = mode
    }

    // MARK: - Coordinator

    func start() {
        let viewModel = KeepsakeDetailViewModel(
            keepsakeId: keepsakeId,
            db: db,
            showsCloseButton: mode == .completion
        )
        let vc = KeepsakeDetailViewController(coordinator: self, viewModel: viewModel)
        navigationController.pushViewController(vc, animated: true)
    }

    // MARK: - KeepsakeDetailCoordinating

    func finish() {
        switch mode {
        case .completion:
            guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return }
            try? db.updateKeepsake(keepsake) {
                $0.status = .done
                if $0.ritualDate == nil { $0.ritualDate = Date() }
            }
            navigationController.popToRootViewController(animated: true)
        case .readOnly:
            navigationController.popViewController(animated: true)
        }
        onFinish?()
    }

    /// 기념품의 파일(리소스, 썸네일)과 Realm 데이터를 모두 삭제하고 홈으로 돌아갑니다
    func deleteAndFinish() {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return }
        MediaStorageManager.shared.deleteKeepsakeFiles(
            resourceFileName: keepsake.resourceFileName,
            thumbnailFileName: keepsake.thumbnailFileName,
            recordType: keepsake.recordType
        )
        try? db.deleteKeepsake(keepsake)
        navigationController.popToRootViewController(animated: true)
        onFinish?()
    }

    func showPhotoViewer(image: UIImage) {
        let vc = PhotoViewerViewController(image: image)
        navigationController.pushViewController(vc, animated: true)
    }

    func showModelViewer(modelURL: URL) {
        if #available(iOS 17.0, *) {
            let vc = ModelViewerViewController(modelURL: modelURL, viewerOnly: true)
            navigationController.pushViewController(vc, animated: true)
        }
    }
}
