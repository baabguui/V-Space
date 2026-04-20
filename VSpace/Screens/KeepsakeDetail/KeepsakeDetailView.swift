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

    let leftQuoteLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.italicSystemFont(ofSize: 18)
        l.textColor = .vsPrimary
        l.text = "\u{201C}"
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    let lastWordsLabel: UILabel = {
        let l = UILabel()
        l.font = .pretendard(.semibold, size: 18)
        l.textAlignment = .center
        l.textColor = .vsSecondary
        l.numberOfLines = 0
        return l
    }()

    let rightQuoteLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.italicSystemFont(ofSize: 18)
        l.textColor = .vsPrimary
        l.text = "\u{201D}"
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    let lastWordsScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator   = false
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()

    private let lastWordsContentView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
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
        l.font = .vsBody
        l.textColor = .vsPrimary
        l.textAlignment = .left
        l.numberOfLines = 0
        return l
    }()

    let memoryNoteScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator   = false
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()

    let memoryNoteLabel: UILabel = {
        let l = UILabel()
        l.font = .vsBody
        l.textColor = .vsSecondary
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

        lastWordsContentView.addSubview(lastWordsLabel)
        lastWordsScrollView.addSubview(lastWordsContentView)

        cardSceneView.addSubview(frontCardView)
        frontCardView.addSubview(thumbnailImageView)
        frontCardView.addSubview(nameLabel)
        frontCardView.addSubview(dateRangeLabel)
        frontCardView.addSubview(lastWordsScrollView)
        frontCardView.addSubview(leftQuoteLabel)
        frontCardView.addSubview(rightQuoteLabel)
        frontCardView.addSubview(frontRitualDateLabel)

        cardSceneView.addSubview(backCardView)
        backCardView.addSubview(abilityMemoryLabel)
        backCardView.addSubview(memoryNoteScrollView)
        memoryNoteScrollView.addSubview(memoryNoteLabel)
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

        leftQuoteLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(24)
            $0.centerY.equalTo(lastWordsScrollView)
        }

        rightQuoteLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(24)
            $0.centerY.equalTo(lastWordsScrollView)
        }

        lastWordsScrollView.snp.makeConstraints {
            $0.top.equalTo(dateRangeLabel.snp.bottom).offset(32)
            $0.bottom.equalTo(frontRitualDateLabel.snp.top).offset(-16)
            $0.leading.equalTo(leftQuoteLabel.snp.trailing).offset(8)
            $0.trailing.equalTo(rightQuoteLabel.snp.leading).offset(-8)
        }

        lastWordsContentView.snp.makeConstraints {
            $0.edges.equalTo(lastWordsScrollView.contentLayoutGuide)
            $0.width.equalTo(lastWordsScrollView.frameLayoutGuide)
            $0.height.greaterThanOrEqualTo(lastWordsScrollView.frameLayoutGuide)
        }

        lastWordsLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.horizontalEdges.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
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

        memoryNoteScrollView.snp.makeConstraints {
            $0.top.equalTo(abilityMemoryLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(mournyRowStackView.snp.top).offset(-44)
        }

        memoryNoteLabel.snp.makeConstraints {
            $0.edges.equalTo(memoryNoteScrollView.contentLayoutGuide)
            $0.width.equalTo(memoryNoteScrollView.frameLayoutGuide)
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

    // MARK: - Public

    /// lastWordsLabel에 oblique(이탤릭) 스타일로 텍스트를 설정합니다
    func setLastWords(_ text: String) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.pretendard(.semibold, size: 18),
            .foregroundColor: UIColor.vsSecondary,
            .obliqueness: 0.3
        ]
        lastWordsLabel.attributedText = NSAttributedString(string: text, attributes: attrs)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundGradientLayer.frame = bounds
    }
}
