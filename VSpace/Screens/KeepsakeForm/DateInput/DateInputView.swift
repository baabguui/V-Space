//
//  DateInputView.swift
//  VSpace
//
//  처음 만난 날 / 보내주는 날 공유 뷰 — UIDatePicker 휠 선택
//

import UIKit
import SnapKit

enum DateInputConfig {
    case acquiredDate
    case disposalDate

    var title: String {
        switch self {
        case .acquiredDate: return NSLocalizedString("date_input.acquired.title", comment: "")
        case .disposalDate: return NSLocalizedString("date_input.disposal.title", comment: "")
        }
    }

    var subtitle: String? {
        switch self {
        case .acquiredDate: return nil
        case .disposalDate: return NSLocalizedString("date_input.disposal.subtitle", comment: "")
        }
    }
}

final class DateInputView: UIView {

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

    let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .wheels
        dp.locale = Locale(identifier: "ko_KR")
        dp.maximumDate = Date()
        return dp
    }()

    let nextButton = VLongButton(
        title: NSLocalizedString("form.button.next", comment: ""),
        style: .black
    )

    // MARK: - Init

    init(config: DateInputConfig) {
        super.init(frame: .zero)
        titleLabel.text = config.title
        subtitleLabel.text = config.subtitle
        subtitleLabel.isHidden = config.subtitle == nil
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
        addSubview(datePicker)
        addSubview(nextButton)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)

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

        datePicker.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(24)
        }

        nextButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
        }
    }

    // MARK: - Actions

    @objc private func dismissKeyboard() {
        endEditing(true)
    }
}
