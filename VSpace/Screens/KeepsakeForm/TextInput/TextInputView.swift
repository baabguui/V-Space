//
//  TextInputView.swift
//  VSpace
//
//  기능 / 일화 / 마지막 말 공유 뷰
//

import UIKit
import SnapKit

enum TextInputConfig {
    case ability      // VTextField, max 50, optional
    case memoryNote   // VMultilineTextField, max 100, optional
    case lastWords    // VMultilineTextField, max 60, optional, 완료 버튼

    var title: String {
        switch self {
        case .ability:    return NSLocalizedString("text_input.ability.title", comment: "")
        case .memoryNote: return NSLocalizedString("text_input.memory.title", comment: "")
        case .lastWords:  return NSLocalizedString("text_input.lastwords.title", comment: "")
        }
    }

    var subtitle: String? {
        switch self {
        case .ability:    return nil
        case .memoryNote: return NSLocalizedString("text_input.memory.subtitle", comment: "")
        case .lastWords:  return NSLocalizedString("text_input.lastwords.subtitle", comment: "")
        }
    }

    var maxLength: Int {
        switch self {
        case .ability:    return 50
        case .memoryNote: return 100
        case .lastWords:  return 60
        }
    }

    var isOptional: Bool { true }

    var buttonTitle: String {
        switch self {
        case .lastWords: return NSLocalizedString("form.button.complete", comment: "")
        default:         return NSLocalizedString("form.button.next", comment: "")
        }
    }

    var buttonStyle: VLongButton.Style {
        switch self {
        case .lastWords: return .accent
        default:         return .black
        }
    }
}

final class TextInputView: UIView {

    // MARK: - UI

    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = .vsWhite
        v.layer.cornerRadius = 70
        v.layer.borderWidth = 4
        v.layer.borderColor = UIColor.vsStroke.cgColor
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .vsBody
        l.textColor = .vsText
        l.textAlignment = .center
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .vsSmall
        l.textColor = .vsSecondary
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()

    let inputField: UIView  // VTextField 또는 VMultilineTextField

    let actionButton: VLongButton

    let skipButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(NSLocalizedString("form.button.skip", comment: ""), for: .normal)
        btn.setTitleColor(.vsSecondary, for: .normal)
        btn.titleLabel?.font = .vsBody
        return btn
    }()

    private let warningLabel: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("text_input.lastwords.warning", comment: "")
        l.font = .vsSmall
        l.textColor = .vsMuted
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let config: TextInputConfig

    // MARK: - Init

    init(config: TextInputConfig) {
        self.config = config

        if case .ability = config {
            inputField = VTextField(
                placeholder: NSLocalizedString("text_input.ability.placeholder", comment: ""),
                maxLength: config.maxLength
            )
        } else {
            let placeholder: String
            switch config {
            case .memoryNote: placeholder = NSLocalizedString("text_input.memory.placeholder", comment: "")
            default:          placeholder = NSLocalizedString("text_input.lastwords.placeholder", comment: "")
            }
            inputField = VMultilineTextField(placeholder: placeholder, maxLength: config.maxLength)
        }

        actionButton = VLongButton(title: config.buttonTitle, style: config.buttonStyle)

        super.init(frame: .zero)
        titleLabel.text = config.title
        subtitleLabel.text = config.subtitle
        subtitleLabel.isHidden = config.subtitle == nil
        warningLabel.isHidden = config != .lastWords
        skipButton.isHidden = config == .lastWords
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .vsSurface

        addSubview(avatarView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(inputField)
        addSubview(skipButton)
        addSubview(actionButton)
        addSubview(warningLabel)

        avatarView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(safeAreaLayoutGuide).offset(60)
            $0.size.equalTo(140)
        }

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(avatarView.snp.bottom).offset(32)
        }

        subtitleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
        }

        inputField.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(40)
        }

        if config == .lastWords {
            warningLabel.snp.makeConstraints {
                $0.horizontalEdges.equalToSuperview().inset(24)
                $0.bottom.equalTo(actionButton.snp.top).offset(-16)
            }
        } else {
            skipButton.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.bottom.equalTo(actionButton.snp.top).offset(-12)
            }
        }

        actionButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
        }
    }
}
