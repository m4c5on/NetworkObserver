nonisolated enum ConnectionState: Equatable, Sendable {
    case unknown
    case online
    case offline
}

nonisolated enum ConnectionTransition: Equatable, Sendable {
    case cameOnline
    case wentOffline
}

/// Debounces flapping: a confirmed state flips only after two consecutive contradicting probes.
/// The very first failure is accepted immediately — there is nothing to protect against yet.
nonisolated struct ConnectionStateMachine: Equatable, Sendable {
    private(set) var confirmed: ConnectionState = .unknown
    private(set) var isVerifying = false

    /// Returns a transition only when a previously confirmed state flips (online ↔ offline).
    mutating func register(isUp: Bool) -> ConnectionTransition? {
        let observed: ConnectionState = isUp ? .online : .offline

        guard observed != confirmed else {
            isVerifying = false
            return nil
        }

        if confirmed == .unknown, observed == .offline {
            confirmed = .offline
            isVerifying = false
            return nil
        }

        guard isVerifying else {
            isVerifying = true
            return nil
        }

        let previous = confirmed
        confirmed = observed
        isVerifying = false

        switch (previous, observed) {
        case (.offline, .online): return .cameOnline
        case (.online, .offline): return .wentOffline
        default: return nil
        }
    }
}

nonisolated struct MonitorUpdate: Equatable, Sendable {
    let result: CheckResult
    let state: ConnectionState
    let isVerifying: Bool
    let transition: ConnectionTransition?
}
