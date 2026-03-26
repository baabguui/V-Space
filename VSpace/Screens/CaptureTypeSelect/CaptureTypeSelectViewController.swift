//
//  CaptureTypeSelectViewController.swift
//  VSpace
//

import UIKit
import RxSwift
import RxCocoa

final class CaptureTypeSelectViewController: BaseViewController {
    
    // MARK: - Properties

    private weak var coordinator: HomeCoordinating?
    private let viewModel: CaptureTypeSelectViewModel
    private let contentView = CaptureTypeSelectView()

    // MARK: - Init

    init(coordinator: HomeCoordinating, viewModel: CaptureTypeSelectViewModel = CaptureTypeSelectViewModel()) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
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
                self?.coordinator?.showObjectCapture()
            })
            .disposed(by: disposeBag)
            
        output.navigateToPlaneCapture
            .subscribe(onNext: { [weak self] in
                self?.coordinator?.showPlaneCapture()
            })
            .disposed(by: disposeBag)
    }
}
