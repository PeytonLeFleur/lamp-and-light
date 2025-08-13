import UserNotifications
import Foundation

enum Notifications {
    static func requestAuth() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return await withCheckedContinuation { cont in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in cont.resume(returning: ok) }
        }
    }

    static func scheduleDaily(hour: Int = 6, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily.plan"])
        var date = DateComponents()
        date.hour = hour
        date.minute = minute
        let trig = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Lamp & Light"
        content.body = "Your daily passage is ready."
        let req = UNNotificationRequest(identifier: "daily.plan", content: content, trigger: trig)
        center.add(req)
    }
} 