//
//  CaptureStatusView.swift
//  VSpace
//
//  USDZ 생성 중(finishing) 및 실패(failed) 상태 오버레이 뷰
//

import UIKit
import SnapKit

final class CaptureStatusView: UIView {

    // MARK: - State

    enum State {
        case finishing
        case failed(canRetry: Bool)
    }

    // MARK: - Callbacks

    var onRetry: (() -> Void)?    // 다시 스캔하기 (session .capturing 상태일 때만 노출)
    var onRestart: (() -> Void)?  // 처음부터 다시 하기

    // MARK: - UI

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = .vsBody
        label.textColor = .vsText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .vsPrimary
        return indicator
    }()

    private let centerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        return stack
    }()

    private lazy var retryButton = VLongButton(
        title: NSLocalizedString("capture.status.retry", comment: ""),
        style: .black
    )

    private lazy var restartButton = VLongButton(
        title: NSLocalizedString("capture.status.restart", comment: ""),
        style: .white
    )

    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .vsWhite

        centerStack.addArrangedSubview(progressLabel)
        centerStack.addArrangedSubview(activityIndicator)
        addSubview(centerStack)

        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        restartButton.addTarget(self, action: #selector(restartTapped), for: .touchUpInside)

        buttonStack.addArrangedSubview(retryButton)
        buttonStack.addArrangedSubview(restartButton)
        addSubview(buttonStack)

        centerStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }

        buttonStack.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).inset(40)
            make.leading.trailing.equalToSuperview().inset(20)
        }
    }

    // MARK: - Public

    func setState(_ state: State) {
        switch state {
        case .finishing:
            progressLabel.text = NSLocalizedString("capture.status.finishing", comment: "")
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            buttonStack.isHidden = true

        case .failed(let canRetry):
            progressLabel.text = NSLocalizedString("capture.status.failed", comment: "")
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            retryButton.isHidden = !canRetry
            buttonStack.isHidden = false
        }
    }

    // MARK: - Actions

    @objc private func retryTapped() {
        onRetry?()
    }

    @objc private func restartTapped() {
        onRestart?()
    }
}
