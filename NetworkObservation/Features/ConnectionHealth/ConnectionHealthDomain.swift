//
//  ConnectionHealthDomain.swift
//  NetworkObservation
//

import Foundation

enum ConnectionHealthDomain {

    /// Sparkline window: how many past probe cycles the latency/cycle-time charts keep.
    static let latencyHistoryLimit = 60

    enum HealthState: CaseIterable, Equatable {
        case good
        case degraded
        case badlyDegraded
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
        /// Gateway latency above which a `.good` candidate is classified `.degraded`; also the
        /// chart's zone boundary (green/yellow). User-configurable, persisted via
        /// ConnectionHealthSettings.
        let gatewayDegradedThresholdMs: Double
        let gatewayDegradedThresholdErrorMessage: String?
        /// Cycle time above which an otherwise-`.good` candidate is downgraded to `.degraded`.
        /// User-configurable, persisted via ConnectionHealthSettings.
        let elapsedDegradedThresholdMs: Double
        let elapsedDegradedThresholdErrorMessage: String?
        /// Gateway latency above which a `.degraded` candidate escalates to `.badlyDegraded`;
        /// user-configurable, persisted via ConnectionHealthSettings.
        let gatewayDegradedBadlyThresholdMs: Double
        let gatewayDegradedBadlyThresholdErrorMessage: String?
        /// Cycle time above which a `.degraded` candidate escalates to `.badlyDegraded`;
        /// user-configurable, persisted via ConnectionHealthSettings.
        let elapsedDegradedBadlyThresholdMs: Double
        let elapsedDegradedBadlyThresholdErrorMessage: String?
        /// Hex colors for the three health tiers (good/degraded/bad), user-configurable via
        /// Settings. No error-message companion: a ColorPicker can't produce an invalid color, so
        /// there's no reject path to surface.
        let goodColorHex: String
        let degradedColorHex: String
        let badColorHex: String
    }

    enum Intent {
        // View
        case intervalChanged(TimeInterval)
        case hysteresisThresholdChanged(Int)
        case gatewayDegradedThresholdChanged(Double)
        case elapsedDegradedThresholdChanged(Double)
        case gatewayDegradedBadlyThresholdChanged(Double)
        case elapsedDegradedBadlyThresholdChanged(Double)
        case goodColorChanged(String)
        case degradedColorChanged(String)
        case badColorChanged(String)

        // Internal
        case _cycleCompleted(gatewayLatencyMs: Double?, external: ProbeResult, elapsedMs: Double)
        case _permissionNeeded
        case _noNetwork
        case _intervalAccepted(TimeInterval)
        case _intervalRejected(minimum: TimeInterval)
        case _hysteresisThresholdAccepted(Int)
        case _hysteresisThresholdRejected(minimum: Int)
        case _gatewayDegradedThresholdAccepted(Double)
        case _gatewayDegradedThresholdRejected(minimum: Double)
        case _elapsedDegradedThresholdAccepted(Double)
        case _elapsedDegradedThresholdRejected(minimum: Double)
        case _gatewayDegradedBadlyThresholdAccepted(Double)
        case _gatewayDegradedBadlyThresholdRejected(minimum: Double)
        case _elapsedDegradedBadlyThresholdAccepted(Double)
        case _elapsedDegradedBadlyThresholdRejected(minimum: Double)

        // Delegate
    }

    enum Effect {
        case persistInterval(TimeInterval)
        case rescheduleProbeLoop(TimeInterval)
        case persistHysteresisThreshold(Int)
        case persistGatewayDegradedThreshold(Double)
        case persistElapsedDegradedThreshold(Double)
        case persistGatewayDegradedBadlyThreshold(Double)
        case persistElapsedDegradedBadlyThreshold(Double)
        case persistGoodColor(String)
        case persistDegradedColor(String)
        case persistBadColor(String)
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
            elapsedHistory: [],
            gatewayDegradedThresholdMs: ConnectionHealthSettings.defaultGatewayDegradedThresholdMs,
            gatewayDegradedThresholdErrorMessage: nil,
            elapsedDegradedThresholdMs: ConnectionHealthSettings.defaultElapsedDegradedThresholdMs,
            elapsedDegradedThresholdErrorMessage: nil,
            gatewayDegradedBadlyThresholdMs: ConnectionHealthSettings.defaultGatewayDegradedBadlyThresholdMs,
            gatewayDegradedBadlyThresholdErrorMessage: nil,
            elapsedDegradedBadlyThresholdMs: ConnectionHealthSettings.defaultElapsedDegradedBadlyThresholdMs,
            elapsedDegradedBadlyThresholdErrorMessage: nil,
            goodColorHex: ConnectionHealthSettings.defaultGoodColorHex,
            degradedColorHex: ConnectionHealthSettings.defaultDegradedColorHex,
            badColorHex: ConnectionHealthSettings.defaultBadColorHex
        )
    }
}
