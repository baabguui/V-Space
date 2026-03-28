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

        nextButton.isHidden = true

        thumbnailImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(120)
        }
        nextButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(40)
        }
    }
}
