//
//  RitualView.swift
//  VSpace
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class RitualView: UIView {

    // MARK: - UI

    let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode   = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        return iv
    }()

    let nextButton = VRoundButton(style: .black, size: .small, iconName: "chevron.right")

    let lastWordsBubbleImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "lastwordsBubble"))
        iv.contentMode = .scaleAspectFit
        iv.alpha       = 0
        return iv
    }()

    let lastWordsLabel: UILabel = {
        let label = UILabel()
        label.font          = .vsBody
        label.textColor     = .vsPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.alpha         = 0
        return label
    }()

    let cardContainerView: UIView = {
        let v = UIView()
        v.backgroundColor    = .vsWhite
        v.layer.cornerRadius = 20
        v.layer.borderWidth  = 4
        v.layer.borderColor  = UIColor.vsPrimary.cgColor
        v.alpha              = 0
        return v
    }()

    let cardThumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode   = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    let cardNameLabel: UILabel = {
        let label = UILabel()
        label.font          = .vsTitle
        label.textColor     = .vsPrimary
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    let cardDetailLabel: UILabel = {
        let label = UILabel()
        label.font          = .vsBody
        label.textColor     = .vsPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let tapGesture = UITapGestureRecognizer()

    // MARK: - Public Interface

    var imageTap: Observable<Void> {
        tapGesture.rx.event.map { _ in () }.asObservable()
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailImageView.layer.cornerRadius     = thumbnailImageView.bounds.width / 2
        cardThumbnailImageView.layer.cornerRadius = cardThumbnailImageView.bounds.width / 2
    }

    // MARK: - Private

    private func setup() {
        backgroundColor = .vsSurface

        thumbnailImageView.addGestureRecognizer(tapGesture)
        addSubview(thumbnailImageView)
        addSubview(nextButton)
        addSubview(lastWordsBubbleImageView)
        addSubview(lastWordsLabel)
        addSubview(cardContainerView)
        cardContainerView.addSubview(cardThumbnailImageView)
        cardContainerView.addSubview(cardNameLabel)
        cardContainerView.addSubview(cardDetailLabel)

        nextButton.isHidden = true

        thumbnailImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(120)
        }
        lastWordsLabel.snp.makeConstraints {
            $0.top.horizontalEdges.equalTo(lastWordsBubbleImageView).inset(40)
            $0.bottom.equalTo(lastWordsBubbleImageView.snp.bottom).inset(40)
        }
        lastWordsBubbleImageView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(30)
            $0.top.equalTo(thumbnailImageView.snp.bottom).offset(24)
        }
        cardContainerView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(64)
            // 썸네일 상단 기준 55pt 위 → Mourny 발이 카드 위에 걸침
            $0.top.equalTo(thumbnailImageView.snp.top).offset(-55)
        }
        cardThumbnailImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(55)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(120)
        }
        cardNameLabel.snp.makeConstraints {
            $0.top.equalTo(cardThumbnailImageView.snp.bottom).offset(35)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
        cardDetailLabel.snp.makeConstraints {
            $0.top.equalTo(cardNameLabel.snp.bottom).offset(35)
            $0.horizontalEdges.bottom.equalToSuperview().inset(20)
        }
        nextButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(40)
        }
    }
}
