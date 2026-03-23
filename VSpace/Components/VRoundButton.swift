//
//  VRoundButton.swift
//  VSpace
//
//  동그란 버튼 컴포넌트
//  스펙: 100×100 / 80x80 ellipse · black(fill #111) / white(fill #FFF + stroke 4px) · 이미지 지원
//

import UIKit
import SnapKit

final class VRoundButton: UIButton {

    // MARK: - Style

    enum Style {
        case black  // fill #111111
        case white  // fill #FFFFFF + stroke 4px #111111
    }
    
    enum Size {
        case large
        case normal
        
        var size: CGFloat {
            switch self {
            case .large:
                100
            case .normal:
                80
            }
        }
    }

    // MARK: - Init

    init(style: Style = .black, size: Size = .normal, iconName: String) {
        super.init(frame: .zero)
        setup(style: style, size: size, iconName: iconName)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    // MARK: - Setup

    private func setup(style: Style, size: Size, iconName: String) {
        var config = Configuration.filled()
        config.image = UIImage(
            systemName: iconName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .bold)
        )
        config.contentInsets = .zero
        config.cornerStyle = .fixed
        config.background.cornerRadius = size.size/2

        switch style {
        case .black:
            config.baseBackgroundColor = .vsPrimary
            config.baseForegroundColor = .vsWhite
        case .white:
            config.baseBackgroundColor = .vsWhite
            config.baseForegroundColor = .vsPrimary
            config.background.strokeWidth = 4
            config.background.strokeColor = .vsStroke
        }

        configuration = config
        
        snp.makeConstraints { make in
            make.size.equalTo(size.size)
        }
    }
}
