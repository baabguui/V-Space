import UIKit
import RealmSwift

// MARK: - HomeCoordinating

protocol HomeCoordinating: AnyObject {
    func showCaptureTypeSelect()
    func showPlaneCapture()
    func showObjectCapture()
    func resumeKeepsakeForm(keepsake: Keepsake)
    func showKeepsakeStatus(keepsake: Keepsake)
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

// MARK: - KeepsakeFormCoordinating

protocol KeepsakeFormCoordinating: AnyObject {
    func showAcquiredDate(keepsakeId: ObjectId)
    func showDisposalDate(keepsakeId: ObjectId)
    func showAbility(keepsakeId: ObjectId)
    func showMemoryNote(keepsakeId: ObjectId)
    func showLastWords(keepsakeId: ObjectId)
    func showFormCompletion(keepsakeId: ObjectId)
    func finishForm()
}
