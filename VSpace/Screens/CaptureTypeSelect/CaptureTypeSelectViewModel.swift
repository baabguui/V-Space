//
//  CaptureTypeSelectViewModel.swift
//  VSpace
//

import Foundation
import RxSwift
import RxCocoa

final class CaptureTypeSelectViewModel {
    
    struct Input {
        let objectCaptureTap: ControlEvent<Void>
        let planeCaptureTap: ControlEvent<Void>
    }
    
    struct Output {
        let navigateToObjectCapture: Observable<Void>
        let navigateToPlaneCapture: Observable<Void>
    }
    
    func transform(input: Input) -> Output {
        return Output(
            navigateToObjectCapture: input.objectCaptureTap.asObservable(),
            navigateToPlaneCapture: input.planeCaptureTap.asObservable()
        )
    }
}
