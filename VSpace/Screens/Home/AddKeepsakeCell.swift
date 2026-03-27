//
//  AddKeepsakeCell.swift
//  VSpace
//

import UIKit
import SnapKit

// MARK: - AddKeepsakeCell (Style: Black, Large -> Circular)

final class AddKeepsakeCell: UICollectionViewCell {
    static let identifier = "AddKeepsakeCell"

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .vsPrimary
        view.clipsToBounds = true
        return view
    }()

    private let plusImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "plus")
        iv.tintColor = .vsWhite
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(plusImageView)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        plusImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(32)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutIfNeeded()
        containerView.layer.cornerRadius = containerView.bounds.width / 2
    }
}
