import Foundation
import OSLog

@MainActor
final class UserDefaultsWatchlistRepository: WatchlistRepository {
    private enum Key {
        static let links = "watchlist.links"
        static let browserAppURL = "watchlist.browserAppURL"
    }

    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "SitePulse", category: "Watchlist")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadLinks() -> [StoredLink] {
        guard let data = defaults.data(forKey: Key.links) else { return [] }
        do {
            return try JSONDecoder().decode([StoredLink].self, from: data)
        } catch {
            logger.error("Failed to decode saved links: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func saveLinks(_ links: [StoredLink]) {
        do {
            defaults.set(try JSONEncoder().encode(links), forKey: Key.links)
        } catch {
            logger.error("Failed to encode links: \(error.localizedDescription, privacy: .public)")
        }
    }

    func loadBrowserAppURL() -> URL? {
        defaults.url(forKey: Key.browserAppURL)
    }

    func saveBrowserAppURL(_ appURL: URL?) {
        if let appURL {
            defaults.set(appURL, forKey: Key.browserAppURL)
        } else {
            defaults.removeObject(forKey: Key.browserAppURL)
        }
    }
}
