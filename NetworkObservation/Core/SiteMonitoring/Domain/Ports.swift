import Foundation

nonisolated protocol ReachabilityChecker: Sendable {
    func check(_ url: URL, method: HTTPMethod) async -> CheckOutcome
}

@MainActor
protocol BrowserService {
    func installedBrowsers() -> [Browser]
    /// `nil` browser means the system default.
    func open(_ url: URL, in browser: Browser?)
}

@MainActor
protocol ConnectionNotifier {
    func requestAuthorization() async
    func notify(_ alert: ConnectionAlert) async
    func clearBadge() async
}

@MainActor
protocol WatchlistRepository {
    func loadLinks() -> [StoredLink]
    func saveLinks(_ links: [StoredLink])
    func loadBrowserAppURL() -> URL?
    func saveBrowserAppURL(_ appURL: URL?)
    func loadCheckInterval() -> Int?
    func saveCheckInterval(_ seconds: Int)
}
