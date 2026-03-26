//
//  PlaneCaptureView.swift
//  VSpace
//

import UIKit
import SnapKit

final class PlaneCaptureView: UIView {

    // MARK: - UI Components

    /// 이미지 선택 후 이미지 재선택을 위한 전체 영역 탭 버튼 (투명)
    let photoTapArea: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .clear
        btn.isHidden = true
        return btn
    }()

    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    let addPhotoButton = VRoundButton(style: .black, size: .large, iconName: "plus")

    private let containerView: UIView = {
        let v = UIView()
        v.clipsToBounds = false
        return v
    }()

    let nextButton = VLongButton(
        title: NSLocalizedString("plane.capture.next", comment: ""),
        style: .black
    )

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("plane.capture.hint", comment: "")
        label.font = .vsSmall
        label.textColor = .vsPlaceholder
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .vsSurface

        addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(addPhotoButton)
        containerView.addSubview(photoTapArea)
        addSubview(hintLabel)
        addSubview(nextButton)

        containerView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(32)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().inset(24)
            make.height.equalTo(containerView.snp.width)
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addPhotoButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        photoTapArea.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(containerView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }

        nextButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).inset(16)
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }

    // MARK: - State

    func showImage(_ image: UIImage) {
        imageView.image = image
        imageView.isHidden = false
        addPhotoButton.isHidden = true
        photoTapArea.isHidden = false
        hintLabel.isHidden = true
    }

    func showPlaceholder() {
        imageView.image = nil
        imageView.isHidden = true
        addPhotoButton.isHidden = false
        photoTapArea.isHidden = true
        hintLabel.isHidden = false
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        // containerView 너비 확정 후 원형 처리
        containerView.layer.cornerRadius = containerView.bounds.width / 2
    }
}
