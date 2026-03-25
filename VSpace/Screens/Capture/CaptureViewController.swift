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
        title = NSLocalizedString("capture.title", comment: "")

        let cancelButton = UIBarButtonItem(
            title: NSLocalizedString("capture.nav.cancel", comment: ""),
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        cancelButton.tintColor = .vsDanger

        let doneButton = UIBarButtonItem(
            title: NSLocalizedString("capture.nav.done", comment: ""),
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
                title: NSLocalizedString("capture.alert.error.title", comment: ""),
                message: String(format: NSLocalizedString("capture.alert.error.message", comment: ""), error.localizedDescription),
                confirmTitle: NSLocalizedString("capture.alert.error.retry", comment: ""),
                cancelTitle: NSLocalizedString("alert.default.cancel", comment: ""),
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
            title: NSLocalizedString("capture.alert.cancel.title", comment: ""),
            message: NSLocalizedString("capture.alert.cancel.message", comment: ""),
            confirmTitle: NSLocalizedString("capture.alert.cancel.confirm", comment: ""),
            confirmStyle: .destructive,
            cancelTitle: NSLocalizedString("capture.alert.cancel.dismiss", comment: ""),
            onConfirm: { [weak self] in
                self?.viewModel.cancelCapture()
            }
        )
    }

    @objc private func doneTapped() {
        showAlert(
            title: NSLocalizedString("capture.alert.done.title", comment: ""),
            message: NSLocalizedString("capture.alert.done.message", comment: ""),
            confirmTitle: NSLocalizedString("capture.alert.done.confirm", comment: ""),
            confirmStyle: .default,
            cancelTitle: NSLocalizedString("alert.default.cancel", comment: ""),
            onConfirm: { [weak self] in
                self?.viewModel.finishCapture()
            }
        )
    }
}
