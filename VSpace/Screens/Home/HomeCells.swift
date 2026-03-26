//
//  HomeCells.swift
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
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        thumbnailImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutIfNeeded()
        containerView.layer.cornerRadius = containerView.bounds.width / 2
    }
    
    func configure(with keepsake: Keepsake) {
        // TODO: thumbnailFileName 활용하여 이미지 로드
        if keepsake.status == .inProgress {
            containerView.layer.borderColor = UIColor.vsSecondary.cgColor
        } else {
            containerView.layer.borderColor = UIColor.vsStroke.cgColor
        }
    }
}

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
        // 원형으로 만들기
        containerView.layer.cornerRadius = containerView.bounds.width / 2
    }
}
