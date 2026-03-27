//
//  KeepsakeCell.swift
//  VSpace
//

import UIKit
import SnapKit

// MARK: - KeepsakeCell (Style: White, Large -> Circular)

final class KeepsakeCell: UICollectionViewCell {
    static let identifier = "KeepsakeCell"

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .vsWhite
        view.layer.borderWidth = 4
        view.layer.borderColor = UIColor.vsStroke.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .clear
        return iv
    }()

    private let statusIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .clear
        iv.tintColor = .vsPrimary
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
        containerView.addSubview(thumbnailImageView)
        containerView.addSubview(statusIconImageView)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        thumbnailImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        statusIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(32)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutIfNeeded()
        containerView.layer.cornerRadius = containerView.bounds.width / 2
    }

    func configure(with keepsake: Keepsake) {
        thumbnailImageView.image = nil
        statusIconImageView.image = nil

        thumbnailImageView.image = MediaStorageManager.shared.loadThumbnail(keepsake.thumbnailFileName)
        
        switch keepsake.status {
        case .done:
            break
        case .inProgress:
            statusIconImageView.image = UIImage(systemName: "ellipsis")
            fallthrough
        default:
            if keepsake.isAvailable {
                statusIconImageView.image = UIImage(systemName: "exclamationmark")
            } else {
                statusIconImageView.image = UIImage(systemName: "hourglass")
            }
            thumbnailImageView.alpha = 0.6
        }
    }
}
