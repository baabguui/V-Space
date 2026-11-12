//
//  AnalyticsTracker.swift
//  VSpace
//
//  Firebase Analytics(GA4) 이벤트 로깅
//

import FirebaseAnalytics

protocol AnalyticsTracking {
    func log(_ event: AnalyticsEvent)
}

enum AnalyticsEvent: Equatable {
    case keepsakeCreated(recordType: String)            // "photo" | "three_d"
    case formInputAction(step: String, action: String)  // step: ability/memory_note/last_words, action: skip/next
    case scanStarted
    case scanCompleted
    case scanSaveTapped
    case scanRescanTapped
    case scanCancelled
    case scanRetryAfterFailure
    case scanRestartedAfterFailure
    case photoCaptureCompleted
    case ritualStarted(source: String)                  // "creation" | "status"
    case ritualCompleted
    case completedKeepsakeRevisited

    var name: String {
        switch self {
        case .keepsakeCreated:             return "keepsake_created"
        case .formInputAction:             return "form_input_action"
        case .scanStarted:                 return "scan_started"
        case .scanCompleted:               return "scan_completed"
        case .scanSaveTapped:              return "scan_save_tapped"
        case .scanRescanTapped:            return "scan_rescan_tapped"
        case .scanCancelled:                return "scan_cancelled"
        case .scanRetryAfterFailure:       return "scan_retry_after_failure"
        case .scanRestartedAfterFailure:   return "scan_restarted_after_failure"
        case .photoCaptureCompleted:       return "photo_capture_completed"
        case .ritualStarted:                return "ritual_started"
        case .ritualCompleted:              return "ritual_completed"
        case .completedKeepsakeRevisited:   return "completed_keepsake_revisited"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .keepsakeCreated(let recordType):
            return ["record_type": recordType]
        case .formInputAction(let step, let action):
            return ["step": step, "action": action]
        case .ritualStarted(let source):
            return ["source": source]
        default:
            return nil
        }
    }
}

final class AnalyticsTracker: AnalyticsTracking {

    static let shared = AnalyticsTracker()
    private init() {}

    func log(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
}
