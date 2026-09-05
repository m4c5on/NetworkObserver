//
//  ConnectionHealthDomain.swift
//  NetworkObservation
//

import Foundation

enum ConnectionHealthDomain {

    /// AC-06: the gateway is classified degraded above this latency; also the chart's zone
    /// boundary (green/yellow) since both read the same threshold.
    static let gatewayDegradedThresholdMs: Double = 100

    /// Sparkline window: how many past probe cycles the latency chart keeps.
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
    }

    enum Intent {
        // View
        case intervalChanged(TimeInterval)

        // Internal
        case _cycleCompleted(gatewayLatencyMs: Double?, external: ProbeResult)
        case _permissionNeeded
        case _noNetwork
        case _intervalAccepted(TimeInterval)
        case _intervalRejected(minimum: TimeInterval)

        // Delegate
    }

    enum Effect {
        case persistInterval(TimeInterval)
        case rescheduleProbeLoop(TimeInterval)
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
            latencyHistory: []
        )
    }
}
