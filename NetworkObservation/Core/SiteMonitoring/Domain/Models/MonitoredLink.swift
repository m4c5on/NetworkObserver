import Foundation

nonisolated struct MonitoredLink: Identifiable, Equatable, Sendable {
    let id: UUID
    let url: URL
    let isPaused: Bool
    let isMuted: Bool
    let request: RequestSettings
    let state: ConnectionState
    let isVerifying: Bool
    let lastResult: CheckResult?
    /// When the current confirmed state began (first probe that pointed to it).
    let stateSince: Date
    /// First probe that contradicted the confirmed state, while it is being verified.
    let pendingSince: Date?
    let consecutiveFailures: Int
    let statistics: LinkStatistics
}

nonisolated extension MonitoredLink {
    static func new(
        id: UUID,
        url: URL,
        startedAt: Date,
        isPaused: Bool = false,
        isMuted: Bool = false,
        request: RequestSettings = .default
    ) -> Self {
        MonitoredLink(
            id: id,
            url: url,
            isPaused: isPaused,
            isMuted: isMuted,
            request: request,
            state: .unknown,
            isVerifying: false,
            lastResult: nil,
            stateSince: startedAt,
            pendingSince: nil,
            consecutiveFailures: 0,
            statistics: .empty
        )
    }

    var stored: StoredLink {
        StoredLink(url: url, isPaused: isPaused, isMuted: isMuted, request: request)
    }

    func applying(_ update: MonitorUpdate, at date: Date) -> Self {
        let didChangeState = update.state != state

        return copy(
            state: update.state,
            isVerifying: update.isVerifying,
            lastResult: .set(update.result),
            stateSince: didChangeState ? (pendingSince ?? date) : stateSince,
            pendingSince: update.isVerifying ? .set(pendingSince ?? date) : .clear,
            consecutiveFailures: update.result.isUp ? 0 : consecutiveFailures + 1,
            statistics: statistics.recording(update.result, startedOutage: didChangeState && update.state == .offline)
        )
    }

    func paused() -> Self {
        copy(isPaused: true, isVerifying: false, pendingSince: .clear)
    }

    /// Monitoring restarts from scratch: the state before the pause can't be trusted anymore.
    func resumed(at date: Date) -> Self {
        copy(
            isPaused: false,
            state: .unknown,
            isVerifying: false,
            lastResult: .clear,
            stateSince: date,
            pendingSince: .clear,
            consecutiveFailures: 0
        )
    }

    func togglingMute() -> Self {
        copy(isMuted: !isMuted)
    }

    func withRequest(_ request: RequestSettings) -> Self {
        copy(request: request)
    }

    func resettingStatistics() -> Self {
        copy(statistics: .empty)
    }

    private func copy(
        isPaused: Bool? = nil,
        isMuted: Bool? = nil,
        request: RequestSettings? = nil,
        state: ConnectionState? = nil,
        isVerifying: Bool? = nil,
        lastResult: Patch<CheckResult> = .keep,
        stateSince: Date? = nil,
        pendingSince: Patch<Date> = .keep,
        consecutiveFailures: Int? = nil,
        statistics: LinkStatistics? = nil
    ) -> Self {
        MonitoredLink(
            id: id,
            url: url,
            isPaused: isPaused ?? self.isPaused,
            isMuted: isMuted ?? self.isMuted,
            request: request ?? self.request,
            state: state ?? self.state,
            isVerifying: isVerifying ?? self.isVerifying,
            lastResult: lastResult.resolved(current: self.lastResult),
            stateSince: stateSince ?? self.stateSince,
            pendingSince: pendingSince.resolved(current: self.pendingSince),
            consecutiveFailures: consecutiveFailures ?? self.consecutiveFailures,
            statistics: statistics ?? self.statistics
        )
    }
}

/// What survives an app relaunch. Statistics and connection state are runtime-only.
nonisolated struct StoredLink: Codable, Equatable, Sendable {
    let url: URL
    let isPaused: Bool
    let isMuted: Bool
    let request: RequestSettings

    private enum CodingKeys: String, CodingKey {
        case url, isPaused, isMuted, request
    }
}

nonisolated extension StoredLink {
    /// Links saved before request settings existed have no `request` and load with the defaults.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            url: try container.decode(URL.self, forKey: .url),
            isPaused: try container.decode(Bool.self, forKey: .isPaused),
            isMuted: try container.decode(Bool.self, forKey: .isMuted),
            request: try container.decodeIfPresent(RequestSettings.self, forKey: .request) ?? .default
        )
    }
}

nonisolated struct ConnectionAlert: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case cameOnline(downtime: TimeInterval)
        case wentOffline(OfflineReason)
    }

    let linkID: UUID
    let url: URL
    let kind: Kind
}
