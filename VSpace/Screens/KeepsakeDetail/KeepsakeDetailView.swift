//
//  KeepsakeDetailView.swift
//  VSpace
//

import UIKit
import SnapKit

final class KeepsakeDetailView: UIView {

    // MARK: - Background

    private let backgroundGradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.type = .radial
        g.colors = [
            UIColor.black.cgColor,
            UIColor(white: 0.45, alpha: 1).cgColor,
            UIColor.white.cgColor
        ]
        g.locations = [0.0, 0.14, 1.0]
        g.startPoint = CGPoint(x: 0.5, y: 0.5)
        g.endPoint   = CGPoint(x: 1.0, y: 1.0)
        return g
    }()

    // MARK: - Card Scene (UIView.transition 대상)

    let cardSceneView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    // MARK: - Front Card

    let frontCardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.borderWidth  = 4
        v.layer.borderColor  = UIColor.black.cgColor
        // clipsToBounds=true는 CATransform3D와 충돌해 반으로 잘리는 현상 발생
        return v
    }()

    let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 60
        return iv
    }()

    let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .pretendard(.semibold, size: 22)
        l.textColor = .vsPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    let dateRangeLabel: UILabel = {
        let l = UILabel()
        l.font = .pretendard(.semibold, size: 22)
        l.textColor = .vsPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    let lastWordsLabel: UILabel = {
        let l = UILabel()
        l.font = .pretendard(.semibold, size: 18)
        l.textColor = .vsPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    let frontRitualDateLabel: UILabel = {
        let l = UILabel()
        l.font = .pretendard(.semibold, size: 14)
        l.textColor = .vsPrimary
        l.alpha = 0.6
        l.textAlignment = .center
        return l
    }()

    // MARK: - Back Card

    let backCardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.borderWidth  = 4
        v.layer.borderColor  = UIColor.black.cgColor
        v.isHidden = true
        return v
    }()

    let abilityMemoryLabel: UILabel = {
        let l = UILabel()
        l.font = .pretendard(.semibold, size: 22)
        l.textColor = .vsPrimary
        l.textAlignment = .left
        l.numberOfLines = 0
        return l
    }()

    let mournyCountLabel: UILabel = {
        let l = UILabel()
        l.font = .pretendard(.semibold, size: 14)
        l.textColor = .vsPrimary
        l.textAlignment = .center
        return l
    }()

    let mournyRowStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = -16
        sv.alignment = .center
        sv.distribution = .fill
        return sv
    }()

    let backRitualDateLabel: UILabel = {
        let l = UILabel()
        l.font = .pretendard(.semibold, size: 14)
        l.textColor = .vsPrimary
        l.alpha = 0.6
        l.textAlignment = .center
        return l
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        setupSubviews()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    // MARK: - Setup

    private func setupLayers() {
        layer.insertSublayer(backgroundGradientLayer, at: 0)
    }

    private func setupSubviews() {
        addSubview(cardSceneView)

        cardSceneView.addSubview(frontCardView)
        frontCardView.addSubview(thumbnailImageView)
        frontCardView.addSubview(nameLabel)
        frontCardView.addSubview(dateRangeLabel)
        frontCardView.addSubview(lastWordsLabel)
        frontCardView.addSubview(frontRitualDateLabel)

        cardSceneView.addSubview(backCardView)
        backCardView.addSubview(abilityMemoryLabel)
        backCardView.addSubview(mournyCountLabel)
        backCardView.addSubview(mournyRowStackView)
        backCardView.addSubview(backRitualDateLabel)
    }

    private func setupConstraints() {
        cardSceneView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalToSuperview().inset(29)
            $0.height.equalTo(cardSceneView.snp.width).multipliedBy(557.0 / 337.0)
        }

        frontCardView.snp.makeConstraints { $0.edges.equalToSuperview() }
        backCardView.snp.makeConstraints  { $0.edges.equalToSuperview() }

        // Front card internals
        thumbnailImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(48)
            $0.size.equalTo(120)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(thumbnailImageView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        dateRangeLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        lastWordsLabel.snp.makeConstraints {
            $0.top.equalTo(dateRangeLabel.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        frontRitualDateLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(24)
            $0.centerX.equalToSuperview()
        }

        // Back card internals
        abilityMemoryLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(32)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        backRitualDateLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(24)
            $0.centerX.equalToSuperview()
        }

        mournyCountLabel.snp.makeConstraints {
            $0.bottom.equalTo(mournyRowStackView.snp.top).offset(-8)
            $0.centerX.equalToSuperview()
        }

        mournyRowStackView.snp.makeConstraints {
            $0.bottom.equalTo(backRitualDateLabel.snp.top).offset(-16)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(50)
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundGradientLayer.frame = bounds
    }
}
