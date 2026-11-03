import Foundation

nonisolated enum LinkWatcherFormatting {
    struct Metric: Identifiable, Equatable {
        let label: String
        let value: String

        var id: String { label }
    }

    static func statusLine(for link: MonitoredLink, now: Date) -> String {
        guard !link.isPaused else { return "Paused" }

        let since = DisplayFormatting.elapsed(now.timeIntervalSince(link.stateSince))
        let reason = link.lastResult?.offlineReason?.displayText

        let parts: [String?] = switch (link.state, link.isVerifying) {
        case (.unknown, false):
            ["Checking…"]
        case (.unknown, true):
            ["Responding — verifying…"]
        case (.online, false):
            ["Online for \(since)", link.lastResult?.latency.map(DisplayFormatting.latency)]
        case (.online, true):
            ["Not responding — verifying…", reason]
        case (.offline, false):
            ["Offline for \(since)", failedChecksText(link.consecutiveFailures), reason]
        case (.offline, true):
            ["Responding again — verifying…", "offline for \(since)"]
        }

        return parts.compactMap { $0 }.joined(separator: " · ")
    }

    static func metrics(for statistics: LinkStatistics) -> [Metric] {
        [
            Metric(label: "Uptime", value: statistics.uptimeRatio.map(DisplayFormatting.percent) ?? "—"),
            Metric(label: "Avg", value: statistics.averageLatency.map(DisplayFormatting.latency) ?? "—"),
            Metric(label: "Checks", value: "\(statistics.totalChecks)"),
            Metric(label: "Outages", value: "\(statistics.outages)"),
        ]
    }

    static func summary(for links: [MonitoredLink]) -> String {
        guard !links.isEmpty else { return "" }
        let active = links.filter { !$0.isPaused }
        let online = active.filter { $0.state == .online }.count
        let offline = active.filter { $0.state == .offline }.count
        let pending = active.count - online - offline
        let paused = links.count - active.count

        let parts: [String?] = [
            "\(online) online",
            offline > 0 ? "\(offline) offline" : nil,
            pending > 0 ? "\(pending) checking" : nil,
            paused > 0 ? "\(paused) paused" : nil,
        ]
        return parts.compactMap { $0 }.joined(separator: " · ")
    }

    static func failedChecksText(_ count: Int) -> String {
        count == 1 ? "1 failed check" : "\(count) failed checks"
    }
}

nonisolated extension LinkWatcherDomain.InputError {
    var message: String {
        switch self {
        case .invalidURL: "Enter a valid http(s) URL"
        case .alreadyWatching: "This URL is already being watched"
        }
    }
}

nonisolated extension URL {
    var displayString: String {
        var text = absoluteString
        if text.hasPrefix("https://") { text.removeFirst("https://".count) }
        if text.hasSuffix("/") { text.removeLast() }
        return text
    }
}
