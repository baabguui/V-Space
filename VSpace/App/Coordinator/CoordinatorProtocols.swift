import UIKit
import RealmSwift

// MARK: - HomeCoordinating

protocol HomeCoordinating: AnyObject {
    func showCaptureTypeSelect()
    func showPlaneCapture()
    func showObjectCapture()
    func resumeKeepsakeForm(keepsake: Keepsake)
    func showKeepsakeStatus(keepsake: Keepsake)
    func showKeepsakeDetail(keepsake: Keepsake)
}

// MARK: - PlaneCaptureCoordinating

protocol PlaneCaptureCoordinating: AnyObject {
    func showImagePicker(from viewController: UIViewController, completion: @escaping (UIImage, UIImage) -> Void)
    func finishCapture(keepsakeId: ObjectId)
}

// MARK: - ObjectCaptureCoordinating

protocol ObjectCaptureCoordinating: AnyObject {
    func showModelViewer(modelURL: URL, onSave: @escaping (UIImage) -> Void, onResume: @escaping () -> Void)
    func finishCapture(keepsakeId: ObjectId)
    func cancelCapture()
}

// MARK: - ActionCoordinating (공통 액션)

protocol KeepsakeActionCoordinating: AnyObject {
    func showRitual()
    func deleteKeepsake()
}

extension KeepsakeActionCoordinating {
    func showRitual() {}
    func deleteKeepsake() {}
}

// MARK: - RitualCoordinating

protocol RitualCoordinating: KeepsakeActionCoordinating {
    func showKeepsakeDetail()
    func showDisposalDateEdit()
    func finishRitual()
}

// MARK: - KeepsakeDetailCoordinating

protocol KeepsakeDetailCoordinating: AnyObject {
    func finish()
    func showPhotoViewer(image: UIImage)
    func showModelViewer(modelURL: URL)
}

// MARK: - KeepsakeFormCoordinating

protocol KeepsakeFormCoordinating: KeepsakeActionCoordinating {
    func showAcquiredDate(keepsakeId: ObjectId)
    func showDisposalDate(keepsakeId: ObjectId)
    func showAbility(keepsakeId: ObjectId)
    func showMemoryNote(keepsakeId: ObjectId)
    func showLastWords(keepsakeId: ObjectId)
    func showFormCompletion(keepsakeId: ObjectId)
    func finishForm()
    func saveAndExit()
}

extension KeepsakeFormCoordinating {
    func showAcquiredDate(keepsakeId: ObjectId) {}
    func showDisposalDate(keepsakeId: ObjectId) {}
    func showAbility(keepsakeId: ObjectId) {}
    func showMemoryNote(keepsakeId: ObjectId) {}
    func showLastWords(keepsakeId: ObjectId) {}
    func showFormCompletion(keepsakeId: ObjectId) {}
    func finishForm() {}
    func saveAndExit() {}
}
