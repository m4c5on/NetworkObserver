//
//  ConnectionHealthDomain.swift
//  NetworkObservation
//

import Foundation

enum ConnectionHealthDomain {

    /// AC-06: the gateway is classified degraded above this latency; also the chart's zone
    /// boundary (green/yellow) since both read the same threshold.
    static let gatewayDegradedThresholdMs: Double = 100

    /// Cycle time (gateway + external run concurrently, so this is roughly their max) above
    /// which a candidate otherwise `.good` is downgraded to `.degraded`; chosen above the
    /// ~300ms both-probes-`.ok` ceiling so a normal cycle never trips it. Never escalates past
    /// `.degraded` — an already-`.unreachable`/`.degraded` candidate is unaffected.
    static let elapsedDegradedThresholdMs: Double = 300

    /// Sparkline window: how many past probe cycles the latency/cycle-time charts keep.
    static let latencyHistoryLimit = 60

    enum HealthState: CaseIterable, Equatable {
        case good
        case degraded
        case unreachable
        case permissionNeeded
        case noNetwork
    }

    enum ProbeResult: CaseIterable, Equatable {
        case ok
        case slow
        case failing
    }

    struct State: Equatable {
        let healthState: HealthState
        let gatewayResult: ProbeResult?
        let externalResult: ProbeResult?
        let probeInterval: TimeInterval
        let errorMessage: String?
        let pendingCandidate: HealthState?
        let pendingCount: Int
        /// Gateway latency per completed cycle, oldest first, capped at `latencyHistoryLimit`;
        /// `nil` marks a cycle where the gateway was unreachable.
        let latencyHistory: [Double?]
        /// AC-04/AC-04b: consecutive cycles a candidate must hold before it becomes `healthState`.
        let hysteresisThreshold: Int
        let hysteresisErrorMessage: String?
        /// Whole-cycle wall-clock time per completed cycle (gateway + external run
        /// concurrently), oldest first, capped at `latencyHistoryLimit`.
        let elapsedHistory: [Double]
    }

    enum Intent {
        // View
        case intervalChanged(TimeInterval)
        case hysteresisThresholdChanged(Int)

        // Internal
        case _cycleCompleted(gatewayLatencyMs: Double?, external: ProbeResult, elapsedMs: Double)
        case _permissionNeeded
        case _noNetwork
        case _intervalAccepted(TimeInterval)
        case _intervalRejected(minimum: TimeInterval)
        case _hysteresisThresholdAccepted(Int)
        case _hysteresisThresholdRejected(minimum: Int)

        // Delegate
    }

    enum Effect {
        case persistInterval(TimeInterval)
        case rescheduleProbeLoop(TimeInterval)
        case persistHysteresisThreshold(Int)
    }
}

extension ConnectionHealthDomain.State {
    static var initial: Self {
        Self(
            healthState: .good,
            gatewayResult: nil,
            externalResult: nil,
            probeInterval: 5,
            errorMessage: nil,
            pendingCandidate: nil,
            pendingCount: 0,
            latencyHistory: [],
            hysteresisThreshold: 3,
            hysteresisErrorMessage: nil,
            elapsedHistory: []
        )
    }
}
