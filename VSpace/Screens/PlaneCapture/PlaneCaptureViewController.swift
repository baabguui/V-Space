//
//  PlaneCaptureViewController.swift
//  VSpace
//

import UIKit
import RxSwift
import RxCocoa
import RxRelay

final class PlaneCaptureViewController: BaseViewController {

    // MARK: - Properties

    private weak var coordinator: HomeCoordinator?
    private let viewModel: PlaneCaptureViewModel
    private let contentView = PlaneCaptureView()
    private let selectedImageRelay = PublishRelay<UIImage>()
    private let croppedImageRelay  = PublishRelay<UIImage>()

    // MARK: - Init

    init(coordinator: HomeCoordinator, viewModel: PlaneCaptureViewModel = PlaneCaptureViewModel()) {
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
        title = NSLocalizedString("plane.capture.title", comment: "")
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    // MARK: - Bind

    private func bindViewModel() {
        let addTap = Observable.merge(
            contentView.addPhotoButton.rx.tap.asObservable(),
            contentView.photoTapArea.rx.tap.asObservable()
        )

        let input = PlaneCaptureViewModel.Input(
            addPhotoTap: addTap,
            selectedImage: selectedImageRelay,
            croppedImage: croppedImageRelay,
            nextTap: contentView.nextButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.openImagePicker
            .subscribe(onNext: { [weak self] in
                self?.presentImagePicker()
            })
            .disposed(by: disposeBag)

        output.displayImage
            .subscribe(onNext: { [weak self] image in
                if let image {
                    self?.contentView.showImage(image)
                } else {
                    self?.contentView.showPlaceholder()
                }
            })
            .disposed(by: disposeBag)

        output.isNextEnabled
            .bind(to: contentView.nextButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.navigateNext
            .subscribe(onNext: { [weak self] keepsakeId in
                self?.coordinator?.showNameInput(keepsakeId: keepsakeId)
            })
            .disposed(by: disposeBag)

        output.errorOccurred
            .subscribe(onNext: { [weak self] error in
                self?.showAlert(
                    title: NSLocalizedString("error.title", comment: ""),
                    message: error.localizedDescription,
                    cancelTitle: nil
                )
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Navigation

    private func presentImagePicker() {
        let pickerVC = ImagePickerViewController()
        let nav = UINavigationController(rootViewController: pickerVC)
        nav.modalPresentationStyle = .fullScreen

        pickerVC.imageSelected
            .take(1)
            .subscribe(onNext: { [weak self, weak nav] originalImage in
                guard let self, let nav else { return }
                let cropVC = CircularCropViewController(image: originalImage)

                cropVC.cropConfirmed
                    .take(1)
                    .subscribe(onNext: { [weak self, weak nav] croppedImage in
                        self?.selectedImageRelay.accept(originalImage)
                        self?.croppedImageRelay.accept(croppedImage)
                        nav?.dismiss(animated: true)
                    })
                    .disposed(by: self.disposeBag)

                nav.pushViewController(cropVC, animated: true)
            })
            .disposed(by: disposeBag)

        present(nav, animated: true)
    }
}
