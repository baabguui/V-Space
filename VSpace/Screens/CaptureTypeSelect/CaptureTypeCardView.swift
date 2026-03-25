//
//  CaptureTypeCardView.swift
//  VSpace
//

import UIKit
import SnapKit

final class CaptureTypeCardView: UIControl {
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .vsWhite
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 4
        view.layer.borderColor = UIColor.vsStroke.cgColor
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .pretendard(.semibold, size: 22)
        label.textColor = .vsPrimary
        return label
    }()
    
    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()
    
    private let arrowIcon: UIImageView = {
        let imgView = UIImageView(image: UIImage(systemName: "chevron.right")!)
        imgView.tintColor = .vsPrimary
        return imgView
    }()
    
    // MARK: - Init
    
    init(title: String, infoItems: [String]) {
        super.init(frame: .zero)
        setupUI(title: title, infoItems: infoItems)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI(title: String, infoItems: [String]) {
        titleLabel.text = title
        
        infoItems.forEach { text in
            let label = UILabel()
            label.text = text
            label.font = .pretendard(.semibold, size: 12)
            label.textColor = .vsPrimary
            label.numberOfLines = 0
            infoStackView.addArrangedSubview(label)
        }
        
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(infoStackView)
        containerView.addSubview(arrowIcon)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(182) // 디자인 파일 GGveL height 반영
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(33)
            make.leading.equalToSuperview().offset(25)
        }
        
        arrowIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.trailing.equalToSuperview().offset(-25)
        }
        
        infoStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(25)
            make.trailing.equalToSuperview().offset(-25)
        }
    }
    
    // MARK: - Highlight State
    
    override var isHighlighted: Bool {
        didSet {
            containerView.alpha = isHighlighted ? 0.7 : 1.0
        }
    }
}
