import Foundation
import Testing
@testable import NetworkObservation

@MainActor
struct AppCoordinatorTests {
    @Test func internetOutagePausesSiteChecksAndNotifies() async {
        var clock = Date(timeIntervalSince1970: 1_000)
        let notifier = NetworkNotifierSpy()
        let coordinator = AppCoordinator(
            connectionHealthStore: ConnectionHealthStore(),
            linkWatcherStore: LinkWatcherStore(
                monitorLink: MonitorLinkDummy(),
                browserService: BrowserServiceDummy(),
                notifier: ConnectionNotifierDummy(),
                repository: WatchlistRepositoryDummy()
            ),
            notificationPreferences: NotificationPreferences(defaults: UserDefaults(suiteName: "AppCoordinatorTests-\(UUID().uuidString)")!),
            networkNotifier: notifier,
            now: { clock }
        )

        coordinator.connectionHealthChanged(healthState: .unreachable, externalResult: .failing)
        #expect(coordinator.linkWatcherStore.state.isNetworkAvailable == false)

        clock = clock.addingTimeInterval(30)
        coordinator.connectionHealthChanged(healthState: .good, externalResult: .ok)
        #expect(coordinator.linkWatcherStore.state.isNetworkAvailable)

        await notifier.waitForEvents(count: 2)
        #expect(notifier.events == [.wentDown, .cameBack(downtime: 30)])
    }
}

@MainActor
private final class NetworkNotifierSpy: NetworkNotifier {
    private(set) var events: [NetworkOutageEvent] = []

    func notifyNetwork(_ event: NetworkOutageEvent) async {
        events.append(event)
    }

    func waitForEvents(count: Int) async {
        for _ in 0..<100 where events.count < count {
            await Task.yield()
        }
    }
}

private struct MonitorLinkDummy: MonitorLinkUseCase {
    func execute(url: URL, request: RequestSettings, pollInterval: Duration) -> AsyncStream<MonitorUpdate> {
        AsyncStream { $0.finish() }
    }
}

@MainActor
private final class BrowserServiceDummy: BrowserService {
    func installedBrowsers() -> [Browser] { [] }
    func open(_ url: URL, in browser: Browser?) {}
}

@MainActor
private final class ConnectionNotifierDummy: ConnectionNotifier {
    func requestAuthorization() async {}
    func notify(_ alert: ConnectionAlert) async {}
    func clearBadge() async {}
}

@MainActor
private final class WatchlistRepositoryDummy: WatchlistRepository {
    func loadLinks() -> [StoredLink] { [] }
    func saveLinks(_ links: [StoredLink]) {}
    func loadBrowserAppURL() -> URL? { nil }
    func saveBrowserAppURL(_ appURL: URL?) {}
    func loadCheckInterval() -> Int? { nil }
    func saveCheckInterval(_ seconds: Int) {}
}
