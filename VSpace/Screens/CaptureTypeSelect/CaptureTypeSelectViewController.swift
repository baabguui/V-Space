//
//  CaptureTypeSelectViewController.swift
//  VSpace
//

import UIKit
import RxSwift
import RxCocoa

final class CaptureTypeSelectViewController: BaseViewController {
    
    // MARK: - Properties
    
    weak var coordinator: HomeCoordinator?
    private let viewModel: CaptureTypeSelectViewModel
    private let contentView = CaptureTypeSelectView()
    
    // MARK: - Init
    
    init(viewModel: CaptureTypeSelectViewModel = CaptureTypeSelectViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        bindViewModel()
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        title = NSLocalizedString("capture.type.title", comment: "")
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func bindViewModel() {
        // UIControl의 controlEvent를 사용하여 탭 바인딩
        let input = CaptureTypeSelectViewModel.Input(
            objectCaptureTap: contentView.objectCaptureCard.rx.controlEvent(.touchUpInside),
            planeCaptureTap: contentView.planeCaptureCard.rx.controlEvent(.touchUpInside)
        )
        
        let output = viewModel.transform(input: input)
        
        output.navigateToObjectCapture
            .subscribe(onNext: { [weak self] in
                self?.coordinator?.showCaptureSession()
            })
            .disposed(by: disposeBag)
            
        output.navigateToPlaneCapture
            .subscribe(onNext: { [weak self] in
                print("Plane Capture selected")
                // TODO: - 평면 캡쳐(RoomCapture 등) 로직 연결 예정
            })
            .disposed(by: disposeBag)
    }
}
