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
        label.font = .vsTitle
        label.textColor = .vsPrimary
        return label
    }()

    private let recommendLabel: UILabel = {
        let label = UILabel()
        label.font = .vsBody
        label.textColor = .vsPrimary
        label.numberOfLines = 0
        return label
    }()

    private let infosLabel: UILabel = {
        let label = UILabel()
        label.font = .vsCaption
        label.textColor = .vsPrimary
        label.numberOfLines = 0
        return label
    }()

    private let arrowIcon: UIImageView = {
        let imgView = UIImageView(image: UIImage(systemName: "chevron.right")!)
        imgView.tintColor = .vsPrimary
        return imgView
    }()

    // MARK: - Init

    /// 캡처 타입 카드 뷰를 초기화합니다
    /// - Parameters:
    ///   - title: 카드 제목
    ///   - recommend: 추천 대상 설명 텍스트
    ///   - infos: 상세 안내 텍스트 (불릿 목록 등)
    init(title: String, recommend: String, infos: String) {
        super.init(frame: .zero)
        setupUI(title: title, recommend: recommend, infos: infos)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    /// UI 컴포넌트를 배치하고 제약 조건을 설정합니다
    /// - Parameters:
    ///   - title: 카드 제목
    ///   - recommend: 추천 대상 설명 텍스트
    ///   - infos: 상세 안내 텍스트
    private func setupUI(title: String, recommend: String, infos: String) {
        titleLabel.text = title
        recommendLabel.text = recommend
        infosLabel.text = infos

        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(arrowIcon)
        containerView.addSubview(recommendLabel)
        containerView.addSubview(infosLabel)

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

        recommendLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(25)
            make.trailing.equalToSuperview().offset(-25)
        }

        infosLabel.snp.makeConstraints { make in
            make.top.equalTo(recommendLabel.snp.bottom).offset(12)
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
