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
    private var captureHostingController: UIHostingController<CaptureView>?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCaptureView()
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

    private func makeCaptureView() -> CaptureView {
        CaptureView(
            session: viewModel.session,
            onStartDetecting: viewModel.startDetecting,
            onStartCapturing: viewModel.startCapturing
        )
    }

    private func setupCaptureView() {
        let hostingController = UIHostingController(rootView: makeCaptureView())
        hostingController.view.backgroundColor = .clear

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        hostingController.didMove(toParent: self)

        captureHostingController = hostingController
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
        case .loading, .ready:
            navigationItem.rightBarButtonItem?.isEnabled = false
            if view.window != nil {
                captureHostingController?.rootView = makeCaptureView()
            }
        case .detecting, .capturing:
            navigationItem.rightBarButtonItem?.isEnabled = true
            navigationItem.leftBarButtonItem?.isEnabled = true
        case .finishing:
            navigationItem.rightBarButtonItem?.isEnabled = false
            navigationItem.leftBarButtonItem?.isEnabled = false
        case .completed(let url):
            pushModelViewer(modelURL: url)
        case .saved, .cancelled:
            if let nav = navigationController,
               let index = nav.viewControllers.firstIndex(of: self),
               index > 0 {
                nav.popToViewController(nav.viewControllers[index - 1], animated: true)
            } else {
                navigationController?.popToRootViewController(animated: true)
            }
        case .failed(let error):
            showAlert(
                title: "오류",
                message: "3D 모델 생성에 실패했습니다.\n\(error.localizedDescription)",
                confirmTitle: "재시도",
                cancelTitle: "취소",
                onConfirm: { [weak self] in
                    self?.viewModel.retryUSDZ()
                }
            )
        }
    }

    // MARK: - Navigation

    private func pushModelViewer(modelURL: URL) {
        let viewer = ModelViewerViewController(modelURL: modelURL) {
            [weak self] in
            self?.viewModel.saveModel()
        } onResume: { [weak self] in
            self?.viewModel.resumeCapturing()
        }
        navigationController?.pushViewController(viewer, animated: true)
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
