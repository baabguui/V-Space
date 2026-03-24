//
//  CaptureViewController.swift
//  VSpace
//
//  ObjectCapture 세션 화면
//

import UIKit
import SwiftUI
import RxSwift
import SnapKit

// MARK: - CaptureViewController

@available(iOS 17.0, *)
final class CaptureViewController: BaseViewController {

    // MARK: - Properties

    private let viewModel = CaptureViewModel()

    // MARK: - UI

    private lazy var loadingOverlay: UIView = {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlay.isHidden = true
        return overlay
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .vsWhite
        return indicator
    }()

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .vsWhite
        label.font = .vsBody
        label.textAlignment = .center
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCaptureView()
        setupLoadingOverlay()
        bindViewModel()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "3D 캡쳐"

        let cancelButton = UIBarButtonItem(
            title: "취소",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        cancelButton.tintColor = .vsDanger

        let doneButton = UIBarButtonItem(
            title: "완료",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
        doneButton.tintColor = .vsPrimary
        doneButton.isEnabled = false   // 캡쳐 시작 전 비활성화

        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = doneButton
    }

    private func setupCaptureView() {
        let cv = CaptureView(viewModel: viewModel)

        let hostingController = UIHostingController(rootView: cv)
        hostingController.view.backgroundColor = .clear

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        hostingController.didMove(toParent: self)
    }

    private func setupLoadingOverlay() {
        view.addSubview(loadingOverlay)
        loadingOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        loadingOverlay.addSubview(activityIndicator)
        loadingOverlay.addSubview(progressLabel)

        activityIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
        }

        progressLabel.snp.makeConstraints { make in
            make.top.equalTo(activityIndicator.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.appState
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.handleState(state)
            })
            .disposed(by: disposeBag)
    }

    private func handleState(_ state: CaptureViewModel.AppState) {
        switch state {
        case .loading:
//            showLoadingOverlay(message: "캡쳐 세션 준비중...")
            navigationItem.rightBarButtonItem?.isEnabled = false
//        case .ready:
//            hideLoadingOverlay()
        case .capturing:
//            hideLoadingOverlay()
            navigationItem.rightBarButtonItem?.isEnabled = true

//        case .finishing:
//            showLoadingOverlay(message: "3D 모델 생성 중...")

        case .completed(let url):
//            hideLoadingOverlay()
            let viewer = ModelViewerViewController(modelURL: url)
            navigationController?.pushViewController(viewer, animated: true)

        case .cancelled:
            print("cancelled")
            navigationController?.popViewController(animated: true)

        case .failed(let error):
//            hideLoadingOverlay()
            print("failed")
            showAlert(
                title: "오류",
                message: "3D 모델 생성에 실패했습니다.\n\(error.localizedDescription)",
                cancelTitle: nil
            )
        default:
            break
        }
    }

    // MARK: - Loading Overlay

    private func showLoadingOverlay(message: String) {
        progressLabel.text = message
        loadingOverlay.isHidden = false
        activityIndicator.startAnimating()
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    private func hideLoadingOverlay() {
        progressLabel.text = ""
        loadingOverlay.isHidden = true
        activityIndicator.stopAnimating()
        navigationItem.leftBarButtonItem?.isEnabled = true
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        showAlert(
            title: "캡쳐 취소",
            message: "현재까지 캡쳐된 사항은 모두 삭제됩니다.\n정말 취소하시겠습니까?",
            confirmTitle: "삭제",
            confirmStyle: .destructive,
            cancelTitle: "계속하기",
            onConfirm: { [weak self] in
                self?.viewModel.cancelCapture()
            }
        )
    }

    @objc private func doneTapped() {
        showAlert(
            title: "3D 모델 생성",
            message: "현재까지 캡쳐된 사항으로 3D 모델을 생성합니다.\n계속하시겠습니까?",
            confirmTitle: "완료",
            confirmStyle: .default,
            cancelTitle: "취소",
            onConfirm: { [weak self] in
                self?.viewModel.finishCapture()
            }
        )
    }
}
