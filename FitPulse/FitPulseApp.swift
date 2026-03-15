//
//  FitPulseApp.swift
//  FitPulse
//
//  Main app entry point with SwiftData, StoreKit 2, HealthKit, and SDK integrations
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct FitPulseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer
    @State private var storeKitManager = StoreKitManager()
    @State private var healthKitService = HealthKitService()
    @State private var notificationManager = NotificationManager()

    init() {
        do {
            let schema = Schema([
                Workout.self,
                BodyMetric.self,
                SleepSession.self,
                UserGoal.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeKitManager)
                .environment(healthKitService)
                .environment(notificationManager)
                .onAppear {
                    Task {
                        await storeKitManager.loadProducts()
                        await storeKitManager.updatePurchasedProducts()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Analytics
        AnalyticsService.shared.initialize()
        AnalyticsService.shared.track(.appOpen)

        // Request ATT permission
        Task { @MainActor in
            _ = await ATTService.shared.requestIfNeeded()
            await AttributionService.shared.requestAttributionIfNeeded()
        }

        return true
    }
}
