//
//  NotificationManager.swift
//  FitPulse
//
//  Manages local notifications for activity reminders, workout reminders, and stand alerts
//

import Foundation
import UserNotifications
import Observation

@MainActor
@Observable
final class NotificationManager: NSObject {

    private(set) var isAuthorized = false

    let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                scheduleDefaultReminders()
            }
        } catch {
            print("Notification authorization error: \(error)")
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule Reminders

    func scheduleDefaultReminders() {
        scheduleWorkoutReminder(hour: 8, minute: 0)
        scheduleMoveReminder()
        scheduleSleepReminder(hour: 22, minute: 0)
    }

    func scheduleWorkoutReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Work Out! 💪"
        content.body = "Don't forget your daily workout. Keep your streak going!"
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_REMINDER"

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "workout_reminder", content: content, trigger: trigger)

        center.add(request)
    }

    func scheduleMoveReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Time to Move! 🏃"
        content.body = "You've been sitting for a while. Take a short walk to close your Stand ring."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: true)
        let request = UNNotificationRequest(identifier: "move_reminder", content: content, trigger: trigger)

        center.add(request)
    }

    func scheduleSleepReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Bedtime Reminder 😴"
        content.body = "Time to wind down. Getting enough sleep improves your health metrics."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "sleep_reminder", content: content, trigger: trigger)

        center.add(request)
    }

    func scheduleWeeklyReport() {
        let content = UNMutableNotificationContent()
        content.title = "Your Weekly Report is Ready! 📊"
        content.body = "Check out your activity summary from the past week."
        content.sound = .default

        var components = DateComponents()
        components.weekday = 2 // Monday
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_report", content: content, trigger: trigger)

        center.add(request)
    }

    func scheduleGoalAchievedNotification(goalType: String) {
        let content = UNMutableNotificationContent()
        content.title = "Goal Achieved! 🎉"
        content.body = "You've reached your \(goalType) goal for today. Amazing work!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "goal_\(goalType)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Manage Reminders

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func updateWorkoutReminder(enabled: Bool, hour: Int, minute: Int) {
        cancelNotification(identifier: "workout_reminder")
        if enabled {
            scheduleWorkoutReminder(hour: hour, minute: minute)
        }
    }

    func updateSleepReminder(enabled: Bool, hour: Int, minute: Int) {
        cancelNotification(identifier: "sleep_reminder")
        if enabled {
            scheduleSleepReminder(hour: hour, minute: minute)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
