//
//  CaptureTypeSelectView.swift
//  VSpace
//

import UIKit
import SnapKit

final class CaptureTypeSelectView: UIView {
    
    // MARK: - UI Components
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24 // 디자인 파일 Group 간의 간격 반영
        return stack
    }()
    
    // 디자인 파일(Node 93erZ)의 데이터 반영
    let objectCaptureCard = CaptureTypeCardView(
        title: NSLocalizedString("capture.type.object.title", comment: ""),
        infoItems: [
            NSLocalizedString("capture.type.object.info1", comment: ""),
            NSLocalizedString("capture.type.object.info2", comment: ""),
            NSLocalizedString("capture.type.object.info3", comment: "")
        ]
    )
    
    let planeCaptureCard = CaptureTypeCardView(
        title: NSLocalizedString("capture.type.plane.title", comment: ""),
        infoItems: [
            NSLocalizedString("capture.type.plane.info1", comment: ""),
            NSLocalizedString("capture.type.plane.info2", comment: "")
        ]
    )
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .vsSurface
        
        addSubview(stackView)
        stackView.addArrangedSubview(objectCaptureCard)
        stackView.addArrangedSubview(planeCaptureCard)
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(40) // Status bar 아래 여백 고려
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }
}
