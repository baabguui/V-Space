//
//  VTextField.swift
//  VSpace
//
//  Single-line 텍스트필드
//  스펙: 배경 #F5F5F5 · radius 12 · 언더라인 5px · 카운터 16 SemiBold 우하단
//

import UIKit
import SnapKit

final class VTextField: UIView {
    private let maxLength: Int

    private let textField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .none
        tf.font = .vsInput
        tf.textColor = .vsText
        tf.tintColor = .vsPrimary
        return tf
    }()

    private let underline: UIView = {
        let v = UIView()
        v.backgroundColor = .vsStroke
        v.layer.cornerRadius = 2.5
        return v
    }()

    private let counterLabel: UILabel = {
        let l = UILabel()
        l.font = .vsCaption
        l.textColor = .vsPrimary
        return l
    }()

    // MARK: - Init

    init(placeholder: String, maxLength: Int = 20) {
        self.maxLength = maxLength
        super.init(frame: .zero)
        setup(placeholder: placeholder)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    // MARK: - Setup

    private func setup(placeholder: String) {
        backgroundColor = .clear
        layer.cornerRadius = 12

        addSubview(textField)
        addSubview(underline)
        addSubview(counterLabel)

        textField.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.horizontalEdges.equalToSuperview()
            $0.top.equalToSuperview()
            $0.height.equalTo(30)
        }

        underline.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(textField.snp.bottom).offset(8)
            $0.width.equalTo(220)
            $0.height.equalTo(5)
        }

        counterLabel.snp.makeConstraints {
            $0.trailing.equalTo(underline.snp.trailing)
            $0.top.equalTo(underline.snp.bottom).offset(14)
            $0.bottom.equalToSuperview()
        }

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: UIFont.vsInput,
                .foregroundColor: UIColor.vsPlaceholder
            ]
        )
        
        textField.textAlignment = .center

        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        updateCounter()
    }

    // MARK: - Actions

    @objc private func textDidChange() {
        var str = textField.text ?? ""
        if str.count > maxLength {
            str = String(str.prefix(maxLength))
            textField.text = str
        }
        updateCounter()
    }

    private func updateCounter() {
        counterLabel.text = "\(textField.text!.count) / \(maxLength)"
    }
}
