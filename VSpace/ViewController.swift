//
//  ViewController.swift
//  VSpace
//
//  Created by baabguui on 3/23/26.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class ViewController: BaseViewController {

    // MARK: - UI

    private let captureButton = VLongButton(title: "입체로 남기기")

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .vsSurface
        setupLayout()
        bindButton()
    }

    // MARK: - Setup

    private func setupLayout() {
        view.addSubview(captureButton)
        captureButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func bindButton() {
        captureButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.startCapture()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Navigation

    private func startCapture() {
        if #available(iOS 17.0, *) {
            let captureVC = CaptureViewController()
            navigationController?.pushViewController(captureVC, animated: true)
        } else {
            showAlert(
                title: "지원 불가",
                message: "3D 캡쳐 기능은 iOS 17 이상에서 사용할 수 있습니다.",
                cancelTitle: nil
            )
        }
    }
}
