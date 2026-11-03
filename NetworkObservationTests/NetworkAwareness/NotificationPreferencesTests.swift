import Foundation
import Testing
@testable import NetworkObservation

@MainActor
struct NotificationPreferencesTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "NotificationPreferencesTests-\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    @Test func everyKindIsEnabledByDefault() {
        let preferences = NotificationPreferences(defaults: makeDefaults())

        #expect(NotificationKind.allCases.allSatisfy { preferences.isEnabled($0) })
    }

    @Test func disablingOneKindLeavesTheOthersOn() {
        let preferences = NotificationPreferences(defaults: makeDefaults())

        preferences.setEnabled(false, for: .siteUp)

        #expect(preferences.isEnabled(.siteUp) == false)
        #expect(preferences.isEnabled(.siteDown))
        #expect(preferences.isEnabled(.internetLost))
    }

    @Test func choicesPersistAcrossLaunches() {
        let defaults = makeDefaults()
        NotificationPreferences(defaults: defaults).setEnabled(false, for: .internetRestored)

        let reloaded = NotificationPreferences(defaults: defaults)

        #expect(reloaded.isEnabled(.internetRestored) == false)
        #expect(reloaded.isEnabled(.internetLost))
    }

    @Test func reEnablingAKindTurnsItBackOn() {
        let preferences = NotificationPreferences(defaults: makeDefaults())
        preferences.setEnabled(false, for: .siteDown)

        preferences.setEnabled(true, for: .siteDown)

        #expect(preferences.isEnabled(.siteDown))
    }

    @Test func alertsAndNetworkEventsMapToTheirKind() throws {
        let url = try #require(URL(string: "https://example.com"))
        #expect(ConnectionAlert(linkID: UUID(), url: url, kind: .wentOffline(.timeout)).notificationKind == .siteDown)
        #expect(ConnectionAlert(linkID: UUID(), url: url, kind: .cameOnline(downtime: 5)).notificationKind == .siteUp)
        #expect(NetworkOutageEvent.wentDown.notificationKind == .internetLost)
        #expect(NetworkOutageEvent.cameBack(downtime: 5).notificationKind == .internetRestored)
    }
}
