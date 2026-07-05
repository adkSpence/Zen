import UserNotifications
import Foundation

@Observable
final class NotificationService {
    static let shared = NotificationService()

    var isAuthorized = false

    private let focusID = "focus.session.end"
    private let breakID = "focus.break.end"

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Task { @MainActor in self.isAuthorized = granted }
        }
    }

    func checkStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleFocusEnd(in seconds: TimeInterval, goalMet: Bool) {
        cancelFocus()
        guard seconds > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Focus session complete"
        var body = "Time for a break. You focused for \(Int(seconds / 60)) minutes."
        if goalMet { body += "\nDaily goal hit — streak +1." }
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let req = UNNotificationRequest(identifier: focusID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    func scheduleBreakEnd(in seconds: TimeInterval) {
        cancelBreak()
        guard seconds > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Break's over"
        content.body = "Ready to focus again?"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let req = UNNotificationRequest(identifier: breakID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    func cancelFocus() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [focusID])
    }

    func cancelBreak() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [breakID])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [focusID, breakID])
    }
}
