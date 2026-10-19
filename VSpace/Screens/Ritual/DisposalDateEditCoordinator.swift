//
//  DisposalDateEditCoordinator.swift
//  VSpace
//
//  KeepsakeStatus → 보내주는 날 재설정 전용 thin coordinator
//

import UIKit
import RealmSwift

final class DisposalDateEditCoordinator: Coordinator, KeepsakeFormCoordinating {

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    var onFinish: (() -> Void)?

    private let keepsakeId: ObjectId
    private let db: KeepsakeDatabaseManaging
    private let storage: MediaStorageManaging
    private let notificationScheduler: NotificationScheduling

    init(
        navigationController: UINavigationController,
        keepsakeId: ObjectId,
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager(),
        storage: MediaStorageManaging = MediaStorageManager.shared,
        notificationScheduler: NotificationScheduling = NotificationScheduler.shared
    ) {
        self.navigationController = navigationController
        self.keepsakeId = keepsakeId
        self.db = db
        self.storage = storage
        self.notificationScheduler = notificationScheduler
    }

    func start() {
        let vc = DateInputViewController(
            coordinator: self,
            viewModel: DateInputViewModel(keepsakeId: keepsakeId, config: .disposalDate),
            config: .disposalDate,
            showsMoreButton: false
        )
        navigationController.pushViewController(vc, animated: true)
    }

    // 날짜 저장 후 → 기존 알림 삭제 → FormCompletion으로 이동
    func handleDisposalDateSaved(keepsakeId: ObjectId) {
        notificationScheduler.cancelDisposalNotification(keepsakeId: keepsakeId)
        showFormCompletion(keepsakeId: keepsakeId)
    }

    // 엘립시스 "저장하고 나가기" → 복귀
    func saveAndExit() {
        navigationController.popViewController(animated: true)
        onFinish?()
    }

    // 엘립시스 "삭제하기" → 파일/DB 삭제 후 홈으로
    func deleteKeepsake() {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else {
            finishForm()
            return
        }
        storage.deleteKeepsakeFiles(
            resourceFileName: keepsake.resourceFileName,
            thumbnailFileName: keepsake.thumbnailFileName,
            recordType: keepsake.recordType
        )
        try? db.deleteKeepsake(keepsake)
        notificationScheduler.cancelDisposalNotification(keepsakeId: keepsakeId)
        finishForm()
    }

    func finishForm() {
        navigationController.popToRootViewController(animated: true)
        onFinish?()
    }

    func showFormCompletion(keepsakeId: ObjectId) {
        let vc = FormCompletionViewController(
            coordinator: self,
            viewModel: FormCompletionViewModel(keepsakeId: keepsakeId)
        )
        navigationController.pushViewController(vc, animated: true)
    }
}
