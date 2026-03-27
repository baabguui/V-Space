//
//  KeepsakeActionView.swift
//  VSpace
//
//  FormCompletion / KeepsakeStatus 공유 레이아웃 뷰
//

import UIKit
import SnapKit

final class KeepsakeActionView: UIView {

    // MARK: - UI

    private let circleView: UIView = {
        let v = UIView()
        v.backgroundColor = .vsWhite
        v.layer.borderWidth = 4
        v.layer.borderColor = UIColor.vsStroke.cgColor
        return v
    }()

    let messageLabel: UILabel = {
        let l = UILabel()
        l.font = .vsTitle
        l.textColor = .vsPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    let primaryButton = VLongButton(title: "", style: .black)
    let secondaryButton: VLongButton

    private let buttonStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.distribution = .fillEqually
        return sv
    }()

    // MARK: - Init

    init(secondaryStyle: VLongButton.Style = .white) {
        self.secondaryButton = VLongButton(title: "", style: secondaryStyle)
        super.init(frame: .zero)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(message: String, primaryTitle: String, secondaryTitle: String) {
        messageLabel.text = message
        primaryButton.configuration?.attributedTitle = AttributedString(
            primaryTitle,
            attributes: AttributeContainer([.font: UIFont.vsTitle])
        )
        secondaryButton.configuration?.attributedTitle = AttributedString(
            secondaryTitle,
            attributes: AttributeContainer([.font: UIFont.vsTitle])
        )
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        circleView.layer.cornerRadius = circleView.bounds.width / 2
    }

    // MARK: - Private

    private func setup() {
        backgroundColor = .vsSurface

        buttonStack.addArrangedSubview(secondaryButton)
        buttonStack.addArrangedSubview(primaryButton)

        addSubview(circleView)
        addSubview(messageLabel)
        addSubview(buttonStack)

        circleView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(safeAreaLayoutGuide).offset(60)
            $0.size.equalTo(176)
        }

        messageLabel.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.top.equalTo(circleView.snp.bottom).offset(60)
        }

        buttonStack.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
        }
    }
}
