import Foundation

nonisolated enum LinkWatcherFormatting {
    struct Metric: Identifiable, Equatable {
        let label: String
        let value: String

        var id: String { label }
    }

    static func statusLine(for link: MonitoredLink, now: Date) -> String {
        guard !link.isPaused else { return String(localized: "Paused") }

        let since = DisplayFormatting.elapsed(now.timeIntervalSince(link.stateSince))
        // An HTTP status code is shown by its own button (with an explanation), not in the text.
        let reason = link.lastResult?.offlineReason.flatMap { reason -> String? in
            if case .httpStatus = reason { return nil }
            return reason.displayText
        }

        let parts: [String?] = switch (link.state, link.isVerifying) {
        case (.unknown, false):
            [String(localized: "Checking…")]
        case (.unknown, true):
            [String(localized: "Responding — verifying…")]
        case (.online, false):
            [String(localized: "Online for \(since)"), link.lastResult?.latency.map(DisplayFormatting.latency)]
        case (.online, true):
            [String(localized: "Not responding — verifying…"), reason]
        case (.offline, false):
            [String(localized: "Offline for \(since)"), failedChecksText(link.consecutiveFailures), reason]
        case (.offline, true):
            [String(localized: "Responding again — verifying…"), String(localized: "offline for \(since)")]
        }

        return parts.compactMap { $0 }.joined(separator: " · ")
    }

    static func metrics(for statistics: LinkStatistics) -> [Metric] {
        [
            Metric(label: String(localized: "Uptime"), value: statistics.uptimeRatio.map(DisplayFormatting.percent) ?? "—"),
            Metric(label: String(localized: "Avg"), value: statistics.averageLatency.map(DisplayFormatting.latency) ?? "—"),
            Metric(label: String(localized: "Checks"), value: "\(statistics.totalChecks)"),
            Metric(label: String(localized: "Outages"), value: "\(statistics.outages)"),
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
            String(localized: "\(online) online"),
            offline > 0 ? String(localized: "\(offline) offline") : nil,
            pending > 0 ? String(localized: "\(pending) checking") : nil,
            paused > 0 ? String(localized: "\(paused) paused") : nil,
        ]
        return parts.compactMap { $0 }.joined(separator: " · ")
    }

    static func failedChecksText(_ count: Int) -> String {
        count == 1 ? String(localized: "1 failed check") : String(localized: "\(count) failed checks")
    }
}

nonisolated extension LinkWatcherDomain.InputError {
    var message: String {
        switch self {
        case .invalidURL: String(localized: "Enter a valid http(s) URL")
        case .alreadyWatching: String(localized: "This URL is already being watched")
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
