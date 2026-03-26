//
//  PlaneCaptureViewModel.swift
//  VSpace
//

import Foundation
import UIKit
import RxSwift
import RxRelay
import RealmSwift

final class PlaneCaptureViewModel {

    struct Input {
        let addPhotoTap: Observable<Void>
        let selectedImage: PublishRelay<UIImage>   // 원본 이미지
        let croppedImage: PublishRelay<UIImage>    // 300×300 원형 마스킹 썸네일
        let nextTap: Observable<Void>
    }

    struct Output {
        let openImagePicker: Observable<Void>
        let displayImage: Observable<UIImage?>
        let isNextEnabled: Observable<Bool>
        let navigateNext: Observable<ObjectId>
        let errorOccurred: Observable<Error>
    }

    private let mediaStorage: MediaStorageManaging
    private let db: KeepsakeDatabaseManaging
    private let disposeBag = DisposeBag()

    init(
        mediaStorage: MediaStorageManaging = MediaStorageManager(),
        db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager()
    ) {
        self.mediaStorage = mediaStorage
        self.db = db
    }

    func transform(input: Input) -> Output {
        let imageRelay   = BehaviorRelay<UIImage?>(value: nil)
        let croppedRelay = BehaviorRelay<UIImage?>(value: nil)
        let errorRelay   = PublishRelay<Error>()
        let navigateRelay = PublishRelay<ObjectId>()

        input.selectedImage
            .bind(to: imageRelay)
            .disposed(by: disposeBag)

        input.croppedImage
            .bind(to: croppedRelay)
            .disposed(by: disposeBag)

        // 원본·썸네일 모두 준비된 경우에만 다음 버튼 활성화
        let isNextEnabled = Observable
            .combineLatest(imageRelay, croppedRelay)
            .map { original, cropped in original != nil && cropped != nil }

        input.nextTap
            .withLatestFrom(Observable.combineLatest(imageRelay, croppedRelay))
            .compactMap { (original, cropped) -> (UIImage, UIImage)? in
                guard let original, let cropped else { return nil }
                return (original, cropped)
            }
            .subscribe(onNext: { [weak self] original, cropped in
                guard let self else { return }
                do {
                    let photoFileName = try self.mediaStorage.savePhoto(original)
                    let thumbFileName = try self.mediaStorage.saveThumbnail(cropped)
                    let keepsake = Keepsake()
                    keepsake.resourceFileName = photoFileName
                    keepsake.thumbnailFileName = thumbFileName
                    keepsake.recordType = .photo
                    keepsake.disposalDate = .distantFuture
                    keepsake.status = .inProgress
                    keepsake.progressStep = 1
                    try self.db.saveKeepsake(keepsake)
                    navigateRelay.accept(keepsake.id)
                } catch {
                    errorRelay.accept(error)
                }
            })
            .disposed(by: disposeBag)

        return Output(
            openImagePicker: input.addPhotoTap,
            displayImage: croppedRelay.asObservable(),
            isNextEnabled: isNextEnabled,
            navigateNext: navigateRelay.asObservable(),
            errorOccurred: errorRelay.asObservable()
        )
    }
}
