//
//  VMultilineTextField.swift
//  VSpace
//
//  Multiline 텍스트필드
//  스펙: 배경 #F5F5F5 · radius 12 · 내부 박스 white + stroke 4px · 카운터 우하단
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class VMultilineTextField: UIView {
    private let maxLength: Int

    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .vsInput
        tv.textColor = .vsText
        tv.tintColor = .vsPrimary
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        tv.textContainer.lineFragmentPadding = 0
        return tv
    }()

    private let textViewContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .vsWhite
        v.layer.cornerRadius = 4
        v.layer.borderWidth = 4
        v.layer.borderColor = UIColor.vsStroke.cgColor
        return v
    }()

    private let placeholderLabel: UILabel = {
        let l = UILabel()
        l.font = .vsInput
        l.textColor = .vsPlaceholder
        l.numberOfLines = 0
        return l
    }()

    private let counterLabel: UILabel = {
        let l = UILabel()
        l.font = .vsCaption
        l.textColor = .vsPrimary
        return l
    }()

    // MARK: - Public

    var rxText: Observable<String> { textView.rx.text.orEmpty.asObservable() }
    var text: String { textView.text ?? "" }

    func setText(_ text: String) {
        textView.text = text
        placeholderLabel.isHidden = !text.isEmpty
        updateCounter()
    }

    // MARK: - Init

    init(placeholder: String, maxLength: Int = 50) {
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
        layer.cornerRadius = 12

        addSubview(textViewContainer)
        textViewContainer.addSubview(textView)
        textViewContainer.addSubview(placeholderLabel)
        addSubview(counterLabel)

        textViewContainer.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.top.equalToSuperview()
            $0.height.equalTo(140)
        }

        textView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        placeholderLabel.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(12)
            $0.top.equalToSuperview().offset(14)
        }

        counterLabel.snp.makeConstraints {
            $0.top.equalTo(textViewContainer.snp.bottom).offset(8)
            $0.trailing.equalTo(textViewContainer)
            $0.bottom.equalToSuperview()
        }

        placeholderLabel.text = placeholder
        textView.delegate = self
        updateCounter()
    }

    // MARK: - Private

    private func updateCounter() {
        counterLabel.text = "\(textView.text!.count) / \(maxLength)"
    }
}

// MARK: - UITextViewDelegate

extension VMultilineTextField: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        var str = textView.text ?? ""
        if str.count > maxLength {
            str = String(str.prefix(maxLength))
            textView.text = str
        }
        placeholderLabel.isHidden = !str.isEmpty
        updateCounter()
    }
}
