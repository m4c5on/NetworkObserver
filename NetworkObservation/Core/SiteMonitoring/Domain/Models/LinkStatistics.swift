nonisolated struct CheckSample: Equatable, Sendable {
    let isUp: Bool
    let latency: Duration?
}

nonisolated struct LinkStatistics: Equatable, Sendable {
    static let historyLimit = 40

    let totalChecks: Int
    let successfulChecks: Int
    let outages: Int
    let totalLatency: Duration
    let recentSamples: [CheckSample]

    static let empty = LinkStatistics(
        totalChecks: 0,
        successfulChecks: 0,
        outages: 0,
        totalLatency: .zero,
        recentSamples: []
    )

    /// Share of successful probes, 0...1. `nil` until the first check completes.
    var uptimeRatio: Double? {
        guard totalChecks > 0 else { return nil }
        return Double(successfulChecks) / Double(totalChecks)
    }

    var averageLatency: Duration? {
        guard successfulChecks > 0 else { return nil }
        return totalLatency / successfulChecks
    }

    func recording(_ result: CheckResult, startedOutage: Bool) -> LinkStatistics {
        let sample = CheckSample(isUp: result.isUp, latency: result.latency)
        return LinkStatistics(
            totalChecks: totalChecks + 1,
            successfulChecks: successfulChecks + (result.isUp ? 1 : 0),
            outages: outages + (startedOutage ? 1 : 0),
            totalLatency: totalLatency + (result.latency ?? .zero),
            recentSamples: Array((recentSamples + [sample]).suffix(Self.historyLimit))
        )
    }
}
