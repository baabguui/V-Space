//
//  DateInputView.swift
//  VSpace
//
//  처음 만난 날 / 보내주는 날 공유 뷰 — 커스텀 UIPickerView
//
//  acquiredDate: 년/월/일 모두 "기억 안남" 항목 + 캐스케이드
//  disposalDate: 년 = 일반값만, 월/일 = "미정" 항목 + 캐스케이드
//

import UIKit
import SnapKit
import RxRelay

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
        v.clipsToBounds = true
        return v
    }()

    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
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

    private let pickerView = UIPickerView()

    let nextButton = VLongButton(
        title: NSLocalizedString("form.button.next", comment: ""),
        style: .black
    )

    // MARK: - Picker Config

    private let config: DateInputConfig
    private let currentYear = Calendar.current.component(.year, from: Date())

    /// acquiredDate만 년 컬럼에 특수값 항목 포함
    private var yearHasSpecial: Bool { config == .acquiredDate }

    /// 월/일 컬럼 특수값 레이블 (acquiredDate: "기억 안남", disposalDate: "미정")
    private var specialLabel: String {
        switch config {
        case .acquiredDate: return "기억 안남"
        case .disposalDate: return "미정"
        }
    }

    private var maxYear: Int {
        switch config {
        case .acquiredDate: return currentYear
        case .disposalDate: return currentYear + 50
        }
    }

    private lazy var years: [Int] = Array((1900...maxYear).reversed())

    // MARK: - Picker State

    private var selectedYear: Int
    private var selectedMonth: Int
    private var selectedDay: Int

    private var yearIsSpecial  = false   // acquiredDate 전용
    private var monthIsSpecial = false
    private var dayIsSpecial   = false

    private var daysInMonth: Int {
        var comps = DateComponents()
        comps.year  = selectedYear
        comps.month = selectedMonth
        guard let date = Calendar.current.date(from: comps) else { return 31 }
        return Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 31
    }

    // MARK: - Relay

    let selectedDateRelay: BehaviorRelay<Date?>

    // MARK: - Init

    init(config: DateInputConfig) {
        self.config = config
        let cal = Calendar.current
        let now  = Date()
        selectedYear  = cal.component(.year,  from: now)
        selectedMonth = cal.component(.month, from: now)
        selectedDay   = cal.component(.day,   from: now)

        let todayComponents = DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)
        let todayDate = Calendar.current.date(from: todayComponents)
        selectedDateRelay = BehaviorRelay<Date?>(value: todayDate)

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

    // MARK: - Public

    func setInitialDate(_ date: Date?) {
        if let date = date {
            let cal = Calendar.current
            selectedYear  = cal.component(.year,  from: date)
            selectedMonth = cal.component(.month, from: date)
            selectedDay   = min(cal.component(.day, from: date), daysInMonth)
            yearIsSpecial = false; monthIsSpecial = false; dayIsSpecial = false
        } else {
            let cal = Calendar.current
            let now = Date()
            selectedYear  = cal.component(.year,  from: now)
            selectedMonth = cal.component(.month, from: now)
            selectedDay   = cal.component(.day,   from: now)
            yearIsSpecial = false; monthIsSpecial = false; dayIsSpecial = false
        }

        pickerView.reloadAllComponents()

        let yearRow = yearHasSpecial
            ? (yearIsSpecial ? 0 : (years.firstIndex(of: selectedYear) ?? 0) + 1)
            : (years.firstIndex(of: selectedYear) ?? 0)
        let monthRow = monthIsSpecial ? 0 : selectedMonth   // row 1-12 = month 1-12
        let dayRow   = dayIsSpecial   ? 0 : selectedDay     // row 1-N  = day 1-N

        pickerView.selectRow(yearRow,  inComponent: 0, animated: false)
        pickerView.selectRow(monthRow, inComponent: 1, animated: false)
        pickerView.selectRow(dayRow,   inComponent: 2, animated: false)
        emitDate()
    }

    // MARK: - Private

    private func emitDate() {
        if yearIsSpecial || monthIsSpecial || dayIsSpecial {
            selectedDateRelay.accept(nil)
            return
        }
        var comps = DateComponents()
        comps.year = selectedYear; comps.month = selectedMonth; comps.day = selectedDay
        selectedDateRelay.accept(Calendar.current.date(from: comps))
    }

    // MARK: - Setup

    func setThumbnail(_ image: UIImage?) {
        thumbnailImageView.image = image
    }

    private func setup() {
        backgroundColor = .vsSurface
        pickerView.dataSource = self
        pickerView.delegate   = self

        addSubview(avatarView)
        avatarView.addSubview(thumbnailImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(pickerView)
        addSubview(nextButton)

        avatarView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(safeAreaLayoutGuide).offset(60)
            $0.size.equalTo(140)
        }

        thumbnailImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
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
        pickerView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(24)
        }
        nextButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
        }
    }
}

// MARK: - UIPickerViewDataSource

extension DateInputView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 3 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return yearHasSpecial ? years.count + 1 : years.count
        case 1:
            // acquiredDate: yearIsSpecial이면 1행("기억 안남")만, 아니면 13행
            // disposalDate: yearIsSpecial 항상 false → 13행
            return yearIsSpecial ? 1 : 13
        case 2:
            return (yearIsSpecial || monthIsSpecial) ? 1 : 1 + daysInMonth
        default:
            return 0
        }
    }
}

// MARK: - UIPickerViewDelegate

extension DateInputView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView,
                    attributedTitleForRow row: Int,
                    forComponent component: Int) -> NSAttributedString? {
        let text: String
        let color: UIColor

        switch component {
        case 0:
            if yearHasSpecial {
                text  = row == 0 ? "기억 안남" : "\(years[row - 1])년"
                color = row == 0 ? .vsSecondary : .vsText
            } else {
                text = "\(years[row])년"; color = .vsText
            }
        case 1:
            text  = row == 0 ? specialLabel : "\(row)월"
            color = row == 0 ? .vsSecondary : .vsText
        case 2:
            text  = row == 0 ? specialLabel : "\(row)일"
            color = row == 0 ? .vsSecondary : .vsText
        default:
            return nil
        }

        return NSAttributedString(string: text, attributes: [.foregroundColor: color])
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            if yearHasSpecial {
                let wasSpecial = yearIsSpecial
                yearIsSpecial  = row == 0
                if row > 0 { selectedYear = years[row - 1] }

                if yearIsSpecial && !wasSpecial {
                    monthIsSpecial = true; dayIsSpecial = true
                    pickerView.reloadComponent(1)
                    pickerView.reloadComponent(2)
                    pickerView.selectRow(0, inComponent: 1, animated: false)
                    pickerView.selectRow(0, inComponent: 2, animated: false)
                } else if !yearIsSpecial && wasSpecial {
                    pickerView.reloadComponent(1)
                } else if !yearIsSpecial {
                    clampAndReloadDay(pickerView)
                }
            } else {
                selectedYear = years[row]
                clampAndReloadDay(pickerView)
            }

        case 1:
            let wasSpecial = monthIsSpecial
            monthIsSpecial  = row == 0
            if row > 0 { selectedMonth = row }

            if monthIsSpecial && !wasSpecial {
                dayIsSpecial = true
                pickerView.reloadComponent(2)
                pickerView.selectRow(0, inComponent: 2, animated: false)
            } else if !monthIsSpecial && wasSpecial {
                let maxDay = daysInMonth
                if selectedDay > maxDay { selectedDay = maxDay }
                pickerView.reloadComponent(2)
                pickerView.selectRow(dayIsSpecial ? 0 : selectedDay, inComponent: 2, animated: false)
            } else if !monthIsSpecial {
                clampAndReloadDay(pickerView)
            }

        case 2:
            dayIsSpecial = row == 0
            if row > 0 { selectedDay = row }

        default:
            break
        }

        emitDate()
    }

    private func clampAndReloadDay(_ pickerView: UIPickerView) {
        let maxDay = daysInMonth
        if selectedDay > maxDay { selectedDay = maxDay }
        pickerView.reloadComponent(2)
        if !dayIsSpecial { pickerView.selectRow(selectedDay, inComponent: 2, animated: false) }
    }
}
