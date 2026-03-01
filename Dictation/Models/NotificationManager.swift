import UserNotifications
import Foundation

// MARK: - NotificationManager

enum NotificationManager {

    private enum Keys {
        static let notificationEnabled = AppConfig.Keys.settingsNotification
    }

    private static let dailyPracticeIdentifier = "daily_practice"

    // MARK: - Permission

    static func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }

        try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Schedule

    static func scheduleDailyPractice(item: DictationItem) async {
        let center = UNUserNotificationCenter.current()

        guard UserDefaults.standard.bool(forKey: Keys.notificationEnabled) else {
            center.removePendingNotificationRequests(withIdentifiers: [dailyPracticeIdentifier])
            return
        }

        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized ||
              settings.authorizationStatus == .provisional else { return }

        let content = UNMutableNotificationContent()
        content.title = AppConfig.notificationTitle
        content.body = String(item.answerText.prefix(40))
        content.sound = .default
        content.userInfo = [
            "itemId": item.id,
            "level":  item.level
        ]

        var components = DateComponents()
        components.hour   = AppConfig.notificationHour
        components.minute = AppConfig.notificationMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: dailyPracticeIdentifier,
            content:    content,
            trigger:    trigger
        )

        try? await center.add(request)
    }

    // MARK: - Cancel

    static func cancelDailyPractice() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyPracticeIdentifier])
    }
}
