/// Raw result of a single HTTP probe, before any business rule is applied.
nonisolated enum CheckOutcome: Equatable, Sendable {
    case responded(statusCode: Int, latency: Duration)
    case failed(OfflineReason)
}

/// A probe interpreted against `WatchPolicy.acceptedStatusCodes`.
nonisolated enum CheckResult: Equatable, Sendable {
    case up(statusCode: Int, latency: Duration)
    case down(OfflineReason)

    var isUp: Bool {
        if case .up = self { true } else { false }
    }

    var latency: Duration? {
        if case .up(_, let latency) = self { latency } else { nil }
    }

    var offlineReason: OfflineReason? {
        if case .down(let reason) = self { reason } else { nil }
    }
}

nonisolated enum OfflineReason: Equatable, Sendable {
    case httpStatus(Int)
    case timeout
    case hostNotFound
    case cannotConnect
    case noInternet
    case secureConnectionFailed
    case other(String)
}
