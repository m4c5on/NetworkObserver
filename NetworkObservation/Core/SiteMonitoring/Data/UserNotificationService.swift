import Foundation
import UserNotifications

nonisolated private let linkIDUserInfoKey = "linkID"

@MainActor
final class UserNotificationService: NSObject, ConnectionNotifier, NetworkNotifier {
    var onNotificationTapped: (@MainActor (UUID) -> Void)?

    private let center: UNUserNotificationCenter
    private let preferences: NotificationPreferences
    private var unseenCount = 0

    init(center: UNUserNotificationCenter = .current(), preferences: NotificationPreferences) {
        self.center = center
        self.preferences = preferences
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func notify(_ alert: ConnectionAlert) async {
        guard preferences.isEnabled(alert.notificationKind) else { return }
        unseenCount += 1

        let host = alert.url.host() ?? alert.url.absoluteString
        let content = UNMutableNotificationContent()
        switch alert.kind {
        case .cameOnline(let downtime):
            content.title = String(localized: "\(host) is up")
            content.body = String(localized: "Back online after \(DisplayFormatting.elapsed(downtime))")
        case .wentOffline(let reason):
            content.title = String(localized: "\(host) is down")
            content.body = reason.displayText
        }
        content.sound = .default
        content.badge = NSNumber(value: unseenCount)
        content.threadIdentifier = alert.linkID.uuidString
        content.userInfo = [linkIDUserInfoKey: alert.linkID.uuidString]

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await center.add(request)
    }

    func notifyNetwork(_ event: NetworkOutageEvent) async {
        guard preferences.isEnabled(event.notificationKind) else { return }
        unseenCount += 1

        let content = UNMutableNotificationContent()
        switch event {
        case .wentDown:
            content.title = String(localized: "Internet connection lost")
            content.body = String(localized: "Site checks are paused until the connection is back.")
        case .cameBack(let downtime):
            content.title = String(localized: "Internet connection restored")
            content.body = String(localized: "Back online after \(DisplayFormatting.elapsed(downtime))")
        }
        content.sound = .default
        content.badge = NSNumber(value: unseenCount)
        content.threadIdentifier = "network"

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await center.add(request)
    }

    func clearBadge() async {
        guard unseenCount > 0 else { return }
        unseenCount = 0
        try? await center.setBadgeCount(0)
    }
}

extension UserNotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let linkID = (response.notification.request.content.userInfo[linkIDUserInfoKey] as? String)
            .flatMap(UUID.init(uuidString:))
        completionHandler()

        guard let linkID else { return }
        Task { @MainActor in
            self.onNotificationTapped?(linkID)
        }
    }
}
