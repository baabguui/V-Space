//
//  NameInputView.swift
//  VSpace
//

import UIKit
import SnapKit

final class NameInputView: UIView {

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
        l.text = NSLocalizedString("name_input.title", comment: "")
        l.font = .vsBody
        l.textColor = .vsText
        l.textAlignment = .center
        return l
    }()

    let nameTextField = VTextField(
        placeholder: NSLocalizedString("name_input.placeholder", comment: ""),
        maxLength: 20
    )

    let nextButton = VLongButton(
        title: NSLocalizedString("form.button.next", comment: ""),
        style: .black
    )

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
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
        addSubview(nameTextField)
        addSubview(nextButton)

        avatarView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(safeAreaLayoutGuide).offset(60)
            $0.size.equalTo(140)
        }

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(avatarView.snp.bottom).offset(32)
        }

        nameTextField.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(40)
            $0.width.equalTo(220)
        }

        nextButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
        }
    }
}
