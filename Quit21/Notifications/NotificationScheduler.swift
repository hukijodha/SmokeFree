import Foundation
import UserNotifications

// MARK: - Section 23: intelligent, sparse, never-shaming local notifications.
// Entirely on-device via UNUserNotificationCenter — no push server exists.

enum NotificationScheduler {
    private static let morningID = "quit21.morning"
    private static let riskWindowID = "quit21.riskWindow"
    private static let milestonePrefix = "quit21.milestone."

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func scheduleMorning(day: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Day \(day)"
        content.body = "Today is Day \(day). Protect your decision."
        content.sound = .default
        var comps = DateComponents()
        comps.hour = 8
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: morningID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Fires near a personally identified high-risk time of day (section 23).
    static func scheduleRiskWindow(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "You're ready for this"
        content.body = "You usually wanted a cigarette around this time. You're ready for it."
        content.sound = .default
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: riskWindowID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func fireMilestone(dayOrLabel: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = "Milestone reached"
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: milestonePrefix + dayOrLabel, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
