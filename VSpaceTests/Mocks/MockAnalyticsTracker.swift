import Foundation
@testable import VSpace

/// `AnalyticsTracking`을 채택하는 테스트용 spy. 실제 Firebase Analytics를 건드리지 않고
/// 로그된 이벤트를 기록해 검증할 수 있게 한다.
final class MockAnalyticsTracker: AnalyticsTracking {

    private(set) var loggedEvents: [AnalyticsEvent] = []

    func log(_ event: AnalyticsEvent) {
        loggedEvents.append(event)
    }
}
