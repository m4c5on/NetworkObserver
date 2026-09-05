//
//  ConnectionHealthReducer.swift
//  NetworkObservation
//

import Foundation

struct ConnectionHealthReducer {
    typealias Domain = ConnectionHealthDomain

    func reduce(
        state: Domain.State,
        intent: Domain.Intent
    ) -> (Domain.State, Domain.Effect?) {
        switch intent {
        case .intervalChanged(let interval):
            return (state, .persistInterval(interval))

        case ._cycleCompleted(let gatewayLatencyMs, let external):
            return (reduceCycleCompleted(state: state, gatewayLatencyMs: gatewayLatencyMs, external: external), nil)

        case ._permissionNeeded:
            return (
                Domain.State(
                    healthState: .permissionNeeded,
                    gatewayResult: nil,
                    externalResult: nil,
                    probeInterval: state.probeInterval,
                    errorMessage: state.errorMessage,
                    pendingCandidate: nil,
                    pendingCount: 0,
                    latencyHistory: state.latencyHistory
                ),
                nil
            )

        case ._noNetwork:
            return (
                Domain.State(
                    healthState: .noNetwork,
                    gatewayResult: nil,
                    externalResult: nil,
                    probeInterval: state.probeInterval,
                    errorMessage: state.errorMessage,
                    pendingCandidate: nil,
                    pendingCount: 0,
                    latencyHistory: state.latencyHistory
                ),
                nil
            )

        case ._intervalAccepted(let interval):
            return (
                Domain.State(
                    healthState: state.healthState,
                    gatewayResult: state.gatewayResult,
                    externalResult: state.externalResult,
                    probeInterval: interval,
                    errorMessage: nil,
                    pendingCandidate: state.pendingCandidate,
                    pendingCount: state.pendingCount,
                    latencyHistory: state.latencyHistory
                ),
                .rescheduleProbeLoop(interval)
            )

        case ._intervalRejected(let minimum):
            return (
                Domain.State(
                    healthState: state.healthState,
                    gatewayResult: state.gatewayResult,
                    externalResult: state.externalResult,
                    probeInterval: state.probeInterval,
                    errorMessage: "Minimum probe interval is \(minimum)s",
                    pendingCandidate: state.pendingCandidate,
                    pendingCount: state.pendingCount,
                    latencyHistory: state.latencyHistory
                ),
                nil
            )
        }
    }

    // MARK: - Private

    private func classifyGateway(latencyMs: Double?) -> Domain.ProbeResult {
        guard let latencyMs else { return .failing }
        return latencyMs > Domain.gatewayDegradedThresholdMs ? .slow : .ok
    }

    /// AC-08 combination table — external is the primary signal, gateway explains the cause.
    private func combine(gateway: Domain.ProbeResult, external: Domain.ProbeResult) -> Domain.HealthState {
        if gateway == .failing || external == .failing {
            return .unreachable
        }
        if external == .slow || gateway == .slow {
            return .degraded
        }
        return .good
    }

    /// AC-04/AC-04b: a candidate only becomes the displayed health state after 3 consecutive
    /// cycles report it (ADR-0005 — hysteresis on the already-combined candidate).
    private func reduceCycleCompleted(
        state: Domain.State,
        gatewayLatencyMs: Double?,
        external: Domain.ProbeResult
    ) -> Domain.State {
        let gatewayResult = classifyGateway(latencyMs: gatewayLatencyMs)
        let candidate = combine(gateway: gatewayResult, external: external)

        var newPendingCandidate: Domain.HealthState?
        var newPendingCount: Int
        var newHealthState = state.healthState

        if candidate == state.healthState {
            newPendingCandidate = nil
            newPendingCount = 0
        } else if candidate == state.pendingCandidate {
            newPendingCandidate = candidate
            newPendingCount = state.pendingCount + 1
        } else {
            newPendingCandidate = candidate
            newPendingCount = 1
        }

        if newPendingCount >= 3 {
            newHealthState = candidate
            newPendingCandidate = nil
            newPendingCount = 0
        }

        var newLatencyHistory = state.latencyHistory
        newLatencyHistory.append(gatewayLatencyMs)
        if newLatencyHistory.count > Domain.latencyHistoryLimit {
            newLatencyHistory.removeFirst(newLatencyHistory.count - Domain.latencyHistoryLimit)
        }

        return Domain.State(
            healthState: newHealthState,
            gatewayResult: gatewayResult,
            externalResult: external,
            probeInterval: state.probeInterval,
            errorMessage: state.errorMessage,
            pendingCandidate: newPendingCandidate,
            pendingCount: newPendingCount,
            latencyHistory: newLatencyHistory
        )
    }
}
