//
//  AnalyticsService.swift
//  FitPulse
//
//  Analytics tracking service (placeholder for Firebase/Amplitude)
//

import Foundation

enum AnalyticsEvent {
    case appOpen
    case onboardingCompleted
    case workoutLogged(type: String)
    case workoutDeleted
    case sleepLogged
    case bodyMetricLogged(type: String)
    case paywallViewed
    case purchaseStarted(productID: String)
    case purchaseCompleted(productID: String)
    case purchaseFailed
    case purchaseRestored
    case healthKitConnected
    case reportViewed
    case goalSet(type: String)
    case signUp(method: String)

    var name: String {
        switch self {
        case .appOpen: return "app_open"
        case .onboardingCompleted: return "onboarding_completed"
        case .workoutLogged: return "workout_logged"
        case .workoutDeleted: return "workout_deleted"
        case .sleepLogged: return "sleep_logged"
        case .bodyMetricLogged: return "body_metric_logged"
        case .paywallViewed: return "paywall_viewed"
        case .purchaseStarted: return "purchase_started"
        case .purchaseCompleted: return "purchase_completed"
        case .purchaseFailed: return "purchase_failed"
        case .purchaseRestored: return "purchase_restored"
        case .healthKitConnected: return "healthkit_connected"
        case .reportViewed: return "report_viewed"
        case .goalSet: return "goal_set"
        case .signUp: return "sign_up"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .workoutLogged(let type): return ["workout_type": type]
        case .bodyMetricLogged(let type): return ["metric_type": type]
        case .purchaseStarted(let id): return ["product_id": id]
        case .purchaseCompleted(let id): return ["product_id": id]
        case .goalSet(let type): return ["goal_type": type]
        case .signUp(let method): return ["method": method]
        default: return [:]
        }
    }
}

@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    private var isInitialized = false

    func initialize() {
        isInitialized = true
        #if DEBUG
        print("[Analytics] Initialized")
        #endif
    }

    func track(_ event: AnalyticsEvent) {
        guard isInitialized else { return }
        #if DEBUG
        print("[Analytics] Event: \(event.name) params: \(event.parameters)")
        #endif
        // TODO: Integrate Firebase Analytics or Amplitude
        // Analytics.logEvent(event.name, parameters: event.parameters)
    }

    func setUserProperty(_ value: String?, forName name: String) {
        #if DEBUG
        print("[Analytics] User property: \(name) = \(value ?? "nil")")
        #endif
    }
}

// MARK: - ATT Service
@MainActor
final class ATTService {
    static let shared = ATTService()
    private init() {}

    func requestIfNeeded() async -> Bool {
        // ATT request placeholder
        #if DEBUG
        print("[ATT] Requesting tracking permission")
        #endif
        return false
    }
}

// MARK: - Attribution Service
@MainActor
final class AttributionService {
    static let shared = AttributionService()
    private init() {}

    func requestAttributionIfNeeded() async {
        #if DEBUG
        print("[Attribution] Requesting attribution data")
        #endif
    }
}
