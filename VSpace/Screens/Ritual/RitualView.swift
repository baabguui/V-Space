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
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.bounds.width / 2
    }

    // MARK: - Private

    private func setup() {
        backgroundColor = .vsSurface

        thumbnailImageView.addGestureRecognizer(tapGesture)
        addSubview(thumbnailImageView)
        addSubview(nextButton)
        addSubview(lastWordsBubbleImageView)
        addSubview(lastWordsLabel)   // 버블 위에 올라오도록 나중에 추가

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
        nextButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(40)
        }
    }
}
