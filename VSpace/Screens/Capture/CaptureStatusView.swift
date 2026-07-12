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

    // MARK: - UI (failed)

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
        style: .bordered
    )

    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    // MARK: - UI (finishing)

    private let finishingContentView = UIView()

    private let illustrationContainerView = UIView()

    private let butterflyImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "butterfly"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let flowerImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "flower"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let morphingShapeView = MorphingShapeView()

    private let pillView: UIView = {
        let view = UIView()
        view.backgroundColor = .vsWhite
        view.layer.borderWidth = 3
        view.layer.borderColor = UIColor.vsText.cgColor
        return view
    }()

    private let pillLabel: UILabel = {
        let label = UILabel()
        label.font = .pretendard(.semibold, size: 16)
        label.textColor = .vsText
        label.textAlignment = .center
        return label
    }()

    private let finishingTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .pretendard(.semibold, size: 22)
        label.textColor = .vsText
        label.textAlignment = .center
        label.text = NSLocalizedString("capture.status.finishing.title", comment: "")
        return label
    }()

    private let finishingSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .pretendard(.regular, size: 16)
        label.textColor = .vsText
        label.textAlignment = .center
        label.text = NSLocalizedString("capture.status.finishing.subtitle", comment: "")
        return label
    }()

    private let finishingPhrases: [String] = (1...11).map {
        NSLocalizedString("capture.status.finishing.phrase_\($0)", comment: "")
    }
    private var phraseIndex = 0
    private var phraseTimer: Timer?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    deinit {
        phraseTimer?.invalidate()
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .vsWhite

        setupFailedViews()
        setupFinishingViews()
    }

    /// 실패 상태에서 쓰이는 스피너/버튼 뷰 계층을 구성합니다
    private func setupFailedViews() {
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

    /// 생성 중 상태에서 쓰이는 타이틀/일러스트/상태 알약 뷰 계층을 구성합니다
    private func setupFinishingViews() {
        addSubview(finishingContentView)

        illustrationContainerView.addSubview(butterflyImageView)
        illustrationContainerView.addSubview(morphingShapeView)
        illustrationContainerView.addSubview(flowerImageView)
        finishingContentView.addSubview(illustrationContainerView)

        pillView.addSubview(pillLabel)
        finishingContentView.addSubview(pillView)

        finishingContentView.addSubview(finishingTitleLabel)
        finishingContentView.addSubview(finishingSubtitleLabel)

        finishingContentView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }

        illustrationContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 318.7, height: 183.6))
        }
        butterflyImageView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.size.equalTo(CGSize(width: 73.62, height: 67.92))
        }
        flowerImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(243.12)
            make.top.equalToSuperview().offset(96.82)
            make.size.equalTo(CGSize(width: 75.58, height: 86.8))
        }
        morphingShapeView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(100.76)
            make.top.equalToSuperview().offset(55.42)
            make.size.equalTo(CGSize(width: 100, height: 100))
        }

        pillView.snp.makeConstraints { make in
            make.top.equalTo(illustrationContainerView.snp.bottom)
            make.leading.trailing.equalTo(self).inset(60)
            make.height.equalTo(54.3)
        }
        pillLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }

        finishingTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(pillView.snp.bottom).offset(58)
            make.leading.trailing.equalToSuperview()
        }
        finishingSubtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(finishingTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        pillView.layer.cornerRadius = pillView.bounds.height / 2
        pillView.layer.masksToBounds = true
    }

    // MARK: - Public

    /// 오버레이 상태를 갱신합니다
    /// - Parameter state: 표시할 상태 (생성 중 / 실패)
    func setState(_ state: State) {
        switch state {
        case .finishing:
            backgroundColor = .vsSurface
            centerStack.isHidden = true
            buttonStack.isHidden = true
            finishingContentView.isHidden = false
            startFinishingAnimations()

        case .failed(let canRetry):
            let hint = NSLocalizedString(
                canRetry ? "capture.status.failed.retry_hint" : "capture.status.failed.restart_hint",
                comment: ""
            )
            backgroundColor = .vsWhite
            finishingContentView.isHidden = true
            stopFinishingAnimations()

            progressLabel.text = NSLocalizedString("capture.status.failed", comment: "") + "\n" + hint
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            retryButton.isHidden = !canRetry
            centerStack.isHidden = false
            buttonStack.isHidden = false
        }
    }

    // MARK: - Private

    /// 상태 문구 순환 타이머와 도형 모핑 애니메이션을 처음부터 시작합니다
    private func startFinishingAnimations() {
        phraseIndex = 0
        pillLabel.text = finishingPhrases[phraseIndex]

        phraseTimer?.invalidate()
        phraseTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            self.phraseIndex += 1
            guard self.phraseIndex < self.finishingPhrases.count else {
                timer.invalidate()
                self.phraseTimer = nil
                return
            }
            self.pillLabel.text = self.finishingPhrases[self.phraseIndex]
        }

        morphingShapeView.startAnimating()
    }

    /// 상태 문구 순환 타이머와 도형 모핑 애니메이션을 멈춥니다
    private func stopFinishingAnimations() {
        phraseTimer?.invalidate()
        phraseTimer = nil
        morphingShapeView.stopAnimating()
    }

    // MARK: - Actions

    @objc private func retryTapped() {
        onRetry?()
    }

    @objc private func restartTapped() {
        onRestart?()
    }
}
