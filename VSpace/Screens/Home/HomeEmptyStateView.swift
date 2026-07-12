//
//  HomeEmptyStateView.swift
//  VSpace
//

import UIKit
import SnapKit

/// keepsake 리스트가 비어있을 때 홈 화면에 노출되는 안내 뷰입니다.
final class HomeEmptyStateView: UIView {

    // MARK: - UI

    private let illustrationImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "horizontalMournyB-arrive"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("home.empty.title", comment: "keepsake 리스트가 비어있을 때 제목")
        label.font = .pretendard(.semibold, size: 22)
        label.textColor = .vsText
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("home.empty.subtitle", comment: "keepsake 리스트가 비어있을 때 안내 문구")
        label.font = .pretendard(.regular, size: 16)
        label.textColor = .vsSecondary
        label.textAlignment = .center
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [illustrationImageView, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(24, after: illustrationImageView)
        return stack
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    // MARK: - Setup

    private func setupLayout() {
        addSubview(stackView)

        illustrationImageView.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.height.equalTo(140)
        }

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }
}
