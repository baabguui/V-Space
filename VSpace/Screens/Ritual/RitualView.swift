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
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        return iv
    }()

    let lastWordsScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator   = false
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()

    /// 짧은 텍스트일 때 세로 중앙 정렬을 위한 컨테이너
    /// height >= scrollView.frameLayoutGuide 로 스크롤뷰 높이 이상을 보장
    private let lastWordsContentView = UIView()

    let lastWordsLabel: UILabel = {
        let label = UILabel()
        label.font          = .vsBody
        label.textColor     = .vsPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
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
        lastWordsBubbleImageView.addSubview(lastWordsScrollView)
        lastWordsScrollView.addSubview(lastWordsContentView)
        lastWordsContentView.addSubview(lastWordsLabel)
        addSubview(cardContainerView)
        cardContainerView.addSubview(cardThumbnailImageView)
        cardContainerView.addSubview(cardNameLabel)
        cardContainerView.addSubview(cardDetailLabel)

        nextButton.isHidden = true
        
        thumbnailImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(120)
        }
        lastWordsBubbleImageView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.top.equalTo(thumbnailImageView.snp.bottom).offset(24)
            $0.bottom.equalTo(nextButton.snp.top).offset(-30)
        }
        lastWordsScrollView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(36)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(200)
        }
        lastWordsContentView.snp.makeConstraints {
            $0.edges.equalTo(lastWordsScrollView.contentLayoutGuide)
            $0.width.equalTo(lastWordsScrollView.frameLayoutGuide)
            // 최소 높이 = 스크롤뷰 frame 높이 → 짧은 텍스트도 세로 중앙 정렬 가능
            $0.height.greaterThanOrEqualTo(lastWordsScrollView.frameLayoutGuide)
        }
        lastWordsLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()           // 짧을 때 세로 중앙
            $0.horizontalEdges.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview()  // 긴 텍스트일 때 컨테이너 높이를 label 기준으로 확장
            $0.bottom.lessThanOrEqualToSuperview()
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
