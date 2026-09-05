//
//  ConnectionHealthDomain.swift
//  NetworkObservation
//

import Foundation

enum ConnectionHealthDomain {

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
            pendingCount: 0
        )
    }
}
