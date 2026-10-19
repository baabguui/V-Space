import Foundation
import RealmSwift
@testable import VSpace

/// `NotificationScheduling`을 채택하는 테스트용 spy. 실제 `UNUserNotificationCenter`를 건드리지 않고
/// 호출된 메서드/인자를 기록해 검증할 수 있게 한다.
final class MockNotificationScheduler: NotificationScheduling {

    struct ScheduleCall: Equatable {
        let keepsakeId: ObjectId
        let name: String
        let disposalDate: Date
    }

    private(set) var scheduleCalls: [ScheduleCall] = []
    private(set) var cancelledKeepsakeIds: [ObjectId] = []
    var authorizationGranted = true

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        completion(authorizationGranted)
    }

    func scheduleDisposalNotification(keepsakeId: ObjectId, name: String, disposalDate: Date) {
        scheduleCalls.append(ScheduleCall(keepsakeId: keepsakeId, name: name, disposalDate: disposalDate))
    }

    func cancelDisposalNotification(keepsakeId: ObjectId) {
        cancelledKeepsakeIds.append(keepsakeId)
    }
}
