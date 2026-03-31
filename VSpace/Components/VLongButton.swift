//
//  VLongButton.swift
//  VSpace
//
//  긴 버튼 컴포넌트
//  스펙: title 기준 상하좌우 padding 30 · radius 56 · fill #111 · 23 SemiBold White
//

import UIKit

final class VLongButton: UIButton {
    
    enum Style {
        case white
        case black
        case accent
        case bordered
    }
    
    // MARK: - Init

    init(title: String, style: Style = .black) {
        super.init(frame: .zero)
        setup(title: title, style: style)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    // MARK: - Setup

    private func setup(title: String, style: Style) {
        var config = Configuration.filled()
        
        switch style {
        case.white:
            config.baseBackgroundColor = .vsWhite
            config.baseForegroundColor = .vsPrimary
        case .black:
            config.baseBackgroundColor = .vsPrimary
            config.baseForegroundColor = .vsWhite
        case .accent:
            config.baseBackgroundColor = .accent
            config.baseForegroundColor = .vsPrimary
        case .bordered:
            config.baseBackgroundColor = .vsWhite
            config.baseForegroundColor = .vsPrimary
            config.background.strokeColor = .vsPrimary
            config.background.strokeWidth = 2
        }
        
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
