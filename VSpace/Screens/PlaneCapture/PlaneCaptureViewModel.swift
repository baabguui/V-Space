//
//  PlaneCaptureViewModel.swift
//  VSpace
//

import Foundation
import UIKit
import RxSwift
import RxRelay

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
        let navigateNext: Observable<Void>
    }

    private let disposeBag = DisposeBag()

    func transform(input: Input) -> Output {
        let imageRelay   = BehaviorRelay<UIImage?>(value: nil)
        let croppedRelay = BehaviorRelay<UIImage?>(value: nil)

        input.selectedImage
            .bind(to: imageRelay)
            .disposed(by: disposeBag)

        input.croppedImage
            .bind(to: croppedRelay)
            .disposed(by: disposeBag)

        let isNextEnabled = Observable
            .combineLatest(imageRelay, croppedRelay)
            .map { original, cropped in original != nil && cropped != nil }

        let navigateNext = input.nextTap
            .withLatestFrom(isNextEnabled)
            .filter { $0 }
            .map { _ in }

        return Output(
            openImagePicker: input.addPhotoTap,
            displayImage: croppedRelay.asObservable(),
            isNextEnabled: isNextEnabled,
            navigateNext: navigateNext
        )
    }
}
