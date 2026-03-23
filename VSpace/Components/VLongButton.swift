//
//  VLongButton.swift
//  VSpace
//
//  긴 버튼 컴포넌트
//  스펙: title 기준 상하좌우 padding 30 · radius 56 · fill #111 · 23 SemiBold White
//

import UIKit

final class VLongButton: UIButton {

    // MARK: - Init

    init(title: String) {
        super.init(frame: .zero)
        setup(title: title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    // MARK: - Setup

    private func setup(title: String) {
        var config = Configuration.filled()
        config.baseBackgroundColor = .vsPrimary
        config.baseForegroundColor = .vsWhite
        config.attributedTitle = AttributedString(
            title,
            attributes: AttributeContainer([
                .font: UIFont.vsTitle
            ])
        )
        config.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        config.cornerStyle = .fixed
        config.background.cornerRadius = 30
        configuration = config
    }
}
