//
//  NotificationScheduler.swift
//  VSpace
//
//  로컬 알림 예약 및 권한 관리
//

import UserNotifications
import RealmSwift
import Realm

final class NotificationScheduler {

    static let shared = NotificationScheduler()
    private init() {}

    // MARK: - Permission

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    // MARK: - Schedule

    /// disposalDate 당일 오전 10시에 알림 예약
    func scheduleDisposalNotification(keepsakeId: ObjectId, name: String, disposalDate: Date) {
        let identifier = notificationId(for: keepsakeId)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.body = "오늘 \(name)\(ireul(name)) 보내주는 날이에요"
        content.sound = .default
        content.userInfo = ["keepsakeId": keepsakeId.stringValue]

        var components = Calendar.current.dateComponents([.year, .month, .day], from: disposalDate)
        components.hour = 10
        components.minute = 0
        components.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel

    func cancelDisposalNotification(keepsakeId: ObjectId) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationId(for: keepsakeId)]
        )
    }

    // MARK: - Private

    private func notificationId(for keepsakeId: ObjectId) -> String {
        "disposal_\(keepsakeId.stringValue)"
    }

    /// 이름 마지막 글자 받침 유무에 따라 "이를" 또는 "를" 반환
    private func ireul(_ name: String) -> String {
        guard let last = name.unicodeScalars.last,
              last.value >= 0xAC00, last.value <= 0xD7A3 else { return "를" }
        return (last.value - 0xAC00) % 28 == 0 ? "를" : "이를"
    }
}
