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

        case .hysteresisThresholdChanged(let threshold):
            return (state, .persistHysteresisThreshold(threshold))

        case .gatewayDegradedThresholdChanged(let threshold):
            return (state, .persistGatewayDegradedThreshold(threshold))

        case .elapsedDegradedThresholdChanged(let threshold):
            return (state, .persistElapsedDegradedThreshold(threshold))

        case .gatewayDegradedBadlyThresholdChanged(let threshold):
            return (state, .persistGatewayDegradedBadlyThreshold(threshold))

        case .elapsedDegradedBadlyThresholdChanged(let threshold):
            return (state, .persistElapsedDegradedBadlyThreshold(threshold))

        case ._cycleCompleted(let gatewayLatencyMs, let external, let elapsedMs):
            return (reduceCycleCompleted(state: state, gatewayLatencyMs: gatewayLatencyMs, external: external, elapsedMs: elapsedMs), nil)

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
                    latencyHistory: state.latencyHistory,
                    hysteresisThreshold: state.hysteresisThreshold,
                    hysteresisErrorMessage: state.hysteresisErrorMessage,
                    elapsedHistory: state.elapsedHistory,
                    gatewayDegradedThresholdMs: state.gatewayDegradedThresholdMs,
                    gatewayDegradedThresholdErrorMessage: state.gatewayDegradedThresholdErrorMessage,
                    elapsedDegradedThresholdMs: state.elapsedDegradedThresholdMs,
                    elapsedDegradedThresholdErrorMessage: state.elapsedDegradedThresholdErrorMessage,
                    gatewayDegradedBadlyThresholdMs: state.gatewayDegradedBadlyThresholdMs,
                    gatewayDegradedBadlyThresholdErrorMessage: state.gatewayDegradedBadlyThresholdErrorMessage,
                    elapsedDegradedBadlyThresholdMs: state.elapsedDegradedBadlyThresholdMs,
                    elapsedDegradedBadlyThresholdErrorMessage: state.elapsedDegradedBadlyThresholdErrorMessage
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
                    latencyHistory: state.latencyHistory,
                    hysteresisThreshold: state.hysteresisThreshold,
                    hysteresisErrorMessage: state.hysteresisErrorMessage,
                    elapsedHistory: state.elapsedHistory,
                    gatewayDegradedThresholdMs: state.gatewayDegradedThresholdMs,
                    gatewayDegradedThresholdErrorMessage: state.gatewayDegradedThresholdErrorMessage,
                    elapsedDegradedThresholdMs: state.elapsedDegradedThresholdMs,
                    elapsedDegradedThresholdErrorMessage: state.elapsedDegradedThresholdErrorMessage,
                    gatewayDegradedBadlyThresholdMs: state.gatewayDegradedBadlyThresholdMs,
                    gatewayDegradedBadlyThresholdErrorMessage: state.gatewayDegradedBadlyThresholdErrorMessage,
                    elapsedDegradedBadlyThresholdMs: state.elapsedDegradedBadlyThresholdMs,
                    elapsedDegradedBadlyThresholdErrorMessage: state.elapsedDegradedBadlyThresholdErrorMessage
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
                    latencyHistory: state.latencyHistory,
                    hysteresisThreshold: state.hysteresisThreshold,
                    hysteresisErrorMessage: state.hysteresisErrorMessage,
                    elapsedHistory: state.elapsedHistory,
                    gatewayDegradedThresholdMs: state.gatewayDegradedThresholdMs,
                    gatewayDegradedThresholdErrorMessage: state.gatewayDegradedThresholdErrorMessage,
                    elapsedDegradedThresholdMs: state.elapsedDegradedThresholdMs,
                    elapsedDegradedThresholdErrorMessage: state.elapsedDegradedThresholdErrorMessage,
                    gatewayDegradedBadlyThresholdMs: state.gatewayDegradedBadlyThresholdMs,
                    gatewayDegradedBadlyThresholdErrorMessage: state.gatewayDegradedBadlyThresholdErrorMessage,
                    elapsedDegradedBadlyThresholdMs: state.elapsedDegradedBadlyThresholdMs,
                    elapsedDegradedBadlyThresholdErrorMessage: state.elapsedDegradedBadlyThresholdErrorMessage
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
                    latencyHistory: state.latencyHistory,
                    hysteresisThreshold: state.hysteresisThreshold,
                    hysteresisErrorMessage: state.hysteresisErrorMessage,
                    elapsedHistory: state.elapsedHistory,
                    gatewayDegradedThresholdMs: state.gatewayDegradedThresholdMs,
                    gatewayDegradedThresholdErrorMessage: state.gatewayDegradedThresholdErrorMessage,
                    elapsedDegradedThresholdMs: state.elapsedDegradedThresholdMs,
                    elapsedDegradedThresholdErrorMessage: state.elapsedDegradedThresholdErrorMessage,
                    gatewayDegradedBadlyThresholdMs: state.gatewayDegradedBadlyThresholdMs,
                    gatewayDegradedBadlyThresholdErrorMessage: state.gatewayDegradedBadlyThresholdErrorMessage,
                    elapsedDegradedBadlyThresholdMs: state.elapsedDegradedBadlyThresholdMs,
                    elapsedDegradedBadlyThresholdErrorMessage: state.elapsedDegradedBadlyThresholdErrorMessage
                ),
                nil
            )

        case ._hysteresisThresholdAccepted(let threshold):
            return (
                Domain.State(
                    healthState: state.healthState,
                    gatewayResult: state.gatewayResult,
                    externalResult: state.externalResult,
                    probeInterval: state.probeInterval,
                    errorMessage: state.errorMessage,
                    pendingCandidate: state.pendingCandidate,
                    pendingCount: state.pendingCount,
                    latencyHistory: state.latencyHistory,
                    hysteresisThreshold: threshold,
                    hysteresisErrorMessage: nil,
                    elapsedHistory: state.elapsedHistory,
                    gatewayDegradedThresholdMs: state.gatewayDegradedThresholdMs,
                    gatewayDegradedThresholdErrorMessage: state.gatewayDegradedThresholdErrorMessage,
                    elapsedDegradedThresholdMs: state.elapsedDegradedThresholdMs,
                    elapsedDegradedThresholdErrorMessage: state.elapsedDegradedThresholdErrorMessage,
                    gatewayDegradedBadlyThresholdMs: state.gatewayDegradedBadlyThresholdMs,
                    gatewayDegradedBadlyThresholdErrorMessage: state.gatewayDegradedBadlyThresholdErrorMessage,
                    elapsedDegradedBadlyThresholdMs: state.elapsedDegradedBadlyThresholdMs,
                    elapsedDegradedBadlyThresholdErrorMessage: state.elapsedDegradedBadlyThresholdErrorMessage
                ),
                nil
            )

        case ._hysteresisThresholdRejected(let minimum):
            return (
                Domain.State(
                    healthState: state.healthState,
                    gatewayResult: state.gatewayResult,
                    externalResult: state.externalResult,
                    probeInterval: state.probeInterval,
                    errorMessage: state.errorMessage,
                    pendingCandidate: state.pendingCandidate,
                    pendingCount: state.pendingCount,
                    latencyHistory: state.latencyHistory,
                    hysteresisThreshold: state.hysteresisThreshold,
                    hysteresisErrorMessage: "Minimum hysteresis is \(minimum) cycle(s)",
                    elapsedHistory: state.elapsedHistory,
                    gatewayDegradedThresholdMs: state.gatewayDegradedThresholdMs,
                    gatewayDegradedThresholdErrorMessage: state.gatewayDegradedThresholdErrorMessage,
                    elapsedDegradedThresholdMs: state.elapsedDegradedThresholdMs,
                    elapsedDegradedThresholdErrorMessage: state.elapsedDegradedThresholdErrorMessage,
                    gatewayDegradedBadlyThresholdMs: state.gatewayDegradedBadlyThresholdMs,
                    gatewayDegradedBadlyThresholdErrorMessage: state.gatewayDegradedBadlyThresholdErrorMessage,
                    elapsedDegradedBadlyThresholdMs: state.elapsedDegradedBadlyThresholdMs,
                    elapsedDegradedBadlyThresholdErrorMessage: state.elapsedDegradedBadlyThresholdErrorMessage
                ),
                nil
            )

        case ._gatewayDegradedThresholdAccepted(let threshold):
            return (
                Domain.State(
                    healthState: state.healthState,
                    gatewayResult: state.gatewayResult,
                    externalResult: state.externalResult,
                    probeInterval: state.probeInterval,
                    errorMessage: state.errorMessage,
                    pendingCandidate: state.pendingCandidate,
                    pendingCount: state.pendingCount,
                    latencyHistory: state.latencyHistory,
                    hysteresisThreshold: state.hysteresisThreshold,
                    hysteresisErrorMessage: state.hysteresisErrorMessage,
                    elapsedHistory: state.elapsedHistory,
                    gatewayDegradedThresholdMs: threshold,
                    gatewayDegradedThresholdErrorMessage: nil,
                    elapsedDegradedThresholdMs: state.elapsedDegradedThresholdMs,
                    elapsedDegradedThresholdErrorMessage: state.elapsedDegradedThresholdErrorMessage,
                    gatewayDegradedBadlyThresholdMs: state.gatewayDegradedBadlyThresholdMs,
                    gatewayDegradedBadlyThresholdErrorMessage: state.gatewayDegradedBadlyThresholdErrorMessage,
                    elapsedDegradedBadlyThresholdMs: state.elapsedDegradedBadlyThresholdMs,
                    elapsedDegradedBadlyThresholdErrorMessage: state.elapsedDegradedBadlyThresholdErrorMessage
                ),
                nil
            )

        case ._gatewayDegradedThresholdRejected(let minimum):
            return (
                Domain.State(
                    healthState: state.healthState,
                    gatewayResult: state.gatewayResult,
                    externalResult: state.externalResult,
                    probeInterval: state.probeInterval,
                    errorMessage: state.errorMessage,
                    pendingCandidate: state.pendingCandidate,
                    pendingCount: state.pendingCount,
                    latencyHistory: state.latencyHistory,
                    hysteresisThreshold: state.hysteresisThreshold,
                    hysteresisErrorMessage: state.hysteresisErrorMessage,
                    elapsedHistory: state.elapsedHistory,
                    gatewayDegradedThresholdMs: state.gatewayDegradedThresholdMs,
                    gatewayDegradedThresholdErrorMessage: "Minimum gateway threshold is \(Int(minimum))ms",
                    elapsedDegradedThresholdMs: state.elapsedDegradedThresholdMs,
                    elapsedDegradedThresholdErrorMessage: state.elapsedDegradedThresholdErrorMessage,
                    gatewayDegradedBadlyThresholdMs: state.gatewayDegradedBadlyThresholdMs,
                    gatewayDegradedBadlyThresholdErrorMessage: state.gatewayDegradedBadlyThresholdErrorMessage,
                    elapsedDegradedBadlyThresholdMs: state.elapsedDegradedBadlyThresholdMs,
                    elapsedDegradedBadlyThresholdErrorMessage: state.elapsedDegradedBadlyThresholdErrorMessage
                ),
                nil
            )

        case ._elapsedDegradedThresholdAccepted(let threshold):
            return (
                Domain.State(
                    healthState: state.healthState,
                    gatewayResult: state.gatewayResult,
                    externalResult: state.externalResult,
                    probeInterval: state.probeInterval,
                    errorMessage: state.errorMessage,
                    pendingCandidate: state.pendingCandidate,
                    pendingCount: state.pendingCount,
                    latencyHistory: state.latencyHistory,
                    hysteresisThreshold: state.hysteresisThreshold,
                    hysteresisErrorMessage: state.hysteresisErrorMessage,
                    elapsedHistory: state.elapsedHistory,
                    gatewayDegradedThresholdMs: state.gatewayDegradedThresholdMs,
                    gatewayDegradedThresholdErrorMessage: state.gatewayDegradedThresholdErrorMessage,
                    elapsedDegradedThresholdMs: threshold,
                    elapsedDegradedThresholdErrorMessage: nil,
                    gatewayDegradedBadlyThresholdMs: state.gatewayDegradedBadlyThresholdMs,
                    gatewayDegradedBadlyThresholdErrorMessage: state.gatewayDegradedBadlyThresholdErrorMessage,
                    elapsedDegradedBadlyThresholdMs: state.elapsedDegradedBadlyThresholdMs,
                    elapsedDegradedBadlyThresholdErrorMessage: state.elapsedDegradedBadlyThresholdErrorMessage
                ),
                nil
            )

        case ._elapsedDegradedThresholdRejected(let minimum):
            return (
                Domain.State(
                    healthState: state.healthState,
                    gatewayResult: state.gatewayResult,
                    externalResult: state.externalResult,
                    probeInterval: state.probeInterval,
                    errorMessage: state.errorMessage,
                    pendingCandidate: state.pendingCandidate,
                    pendingCount: state.pendingCount,
                    latencyHistory: state.latencyHistory,
                    hysteresisThreshold: state.hysteresisThreshold,
                    hysteresisErrorMessage: state.hysteresisErrorMessage,
                    elapsedHistory: state.elapsedHistory,
                    gatewayDegradedThresholdMs: state.gatewayDegradedThresholdMs,
                    gatewayDegradedThresholdErrorMessage: state.gatewayDegradedThresholdErrorMessage,
                    elapsedDegradedThresholdMs: state.elapsedDegradedThresholdMs,
                    elapsedDegradedThresholdErrorMessage: "Minimum elapsed threshold is \(Int(minimum))ms",
                    gatewayDegradedBadlyThresholdMs: state.gatewayDegradedBadlyThresholdMs,
                    gatewayDegradedBadlyThresholdErrorMessage: state.gatewayDegradedBadlyThresholdErrorMessage,
                    elapsedDegradedBadlyThresholdMs: state.elapsedDegradedBadlyThresholdMs,
                    elapsedDegradedBadlyThresholdErrorMessage: state.elapsedDegradedBadlyThresholdErrorMessage
                ),
                nil
            )

        case ._gatewayDegradedBadlyThresholdAccepted(let threshold):
            return (
                Domain.State(
                    healthState: state.healthState,
                    gatewayResult: state.gatewayResult,
                    externalResult: state.externalResult,
                    probeInterval: state.probeInterval,
                    errorMessage: state.errorMessage,
                    pendingCandidate: state.pendingCandidate,
                    pendingCount: state.pendingCount,
                    latencyHistory: state.latencyHistory,
                    hysteresisThreshold: state.hysteresisThreshold,
                    hysteresisErrorMessage: state.hysteresisErrorMessage,
                    elapsedHistory: state.elapsedHistory,
                    gatewayDegradedThresholdMs: state.gatewayDegradedThresholdMs,
                    gatewayDegradedThresholdErrorMessage: state.gatewayDegradedThresholdErrorMessage,
                    elapsedDegradedThresholdMs: state.elapsedDegradedThresholdMs,
                    elapsedDegradedThresholdErrorMessage: state.elapsedDegradedThresholdErrorMessage,
                    gatewayDegradedBadlyThresholdMs: threshold,
                    gatewayDegradedBadlyThresholdErrorMessage: nil,
                    elapsedDegradedBadlyThresholdMs: state.elapsedDegradedBadlyThresholdMs,
                    elapsedDegradedBadlyThresholdErrorMessage: state.elapsedDegradedBadlyThresholdErrorMessage
                ),
                nil
            )

        case ._gatewayDegradedBadlyThresholdRejected(let minimum):
            return (
                Domain.State(
                    healthState: state.healthState,
                    gatewayResult: state.gatewayResult,
                    externalResult: state.externalResult,
                    probeInterval: state.probeInterval,
                    errorMessage: state.errorMessage,
                    pendingCandidate: state.pendingCandidate,
                    pendingCount: state.pendingCount,
                    latencyHistory: state.latencyHistory,
                    hysteresisThreshold: state.hysteresisThreshold,
                    hysteresisErrorMessage: state.hysteresisErrorMessage,
                    elapsedHistory: state.elapsedHistory,
                    gatewayDegradedThresholdMs: state.gatewayDegradedThresholdMs,
                    gatewayDegradedThresholdErrorMessage: state.gatewayDegradedThresholdErrorMessage,
                    elapsedDegradedThresholdMs: state.elapsedDegradedThresholdMs,
                    elapsedDegradedThresholdErrorMessage: state.elapsedDegradedThresholdErrorMessage,
                    gatewayDegradedBadlyThresholdMs: state.gatewayDegradedBadlyThresholdMs,
                    gatewayDegradedBadlyThresholdErrorMessage: "Minimum gateway badly threshold is \(Int(minimum))ms",
                    elapsedDegradedBadlyThresholdMs: state.elapsedDegradedBadlyThresholdMs,
                    elapsedDegradedBadlyThresholdErrorMessage: state.elapsedDegradedBadlyThresholdErrorMessage
                ),
                nil
            )

        case ._elapsedDegradedBadlyThresholdAccepted(let threshold):
            return (
                Domain.State(
                    healthState: state.healthState,
                    gatewayResult: state.gatewayResult,
                    externalResult: state.externalResult,
                    probeInterval: state.probeInterval,
                    errorMessage: state.errorMessage,
                    pendingCandidate: state.pendingCandidate,
                    pendingCount: state.pendingCount,
                    latencyHistory: state.latencyHistory,
                    hysteresisThreshold: state.hysteresisThreshold,
                    hysteresisErrorMessage: state.hysteresisErrorMessage,
                    elapsedHistory: state.elapsedHistory,
                    gatewayDegradedThresholdMs: state.gatewayDegradedThresholdMs,
                    gatewayDegradedThresholdErrorMessage: state.gatewayDegradedThresholdErrorMessage,
                    elapsedDegradedThresholdMs: state.elapsedDegradedThresholdMs,
                    elapsedDegradedThresholdErrorMessage: state.elapsedDegradedThresholdErrorMessage,
                    gatewayDegradedBadlyThresholdMs: state.gatewayDegradedBadlyThresholdMs,
                    gatewayDegradedBadlyThresholdErrorMessage: state.gatewayDegradedBadlyThresholdErrorMessage,
                    elapsedDegradedBadlyThresholdMs: threshold,
                    elapsedDegradedBadlyThresholdErrorMessage: nil
                ),
                nil
            )

        case ._elapsedDegradedBadlyThresholdRejected(let minimum):
            return (
                Domain.State(
                    healthState: state.healthState,
                    gatewayResult: state.gatewayResult,
                    externalResult: state.externalResult,
                    probeInterval: state.probeInterval,
                    errorMessage: state.errorMessage,
                    pendingCandidate: state.pendingCandidate,
                    pendingCount: state.pendingCount,
                    latencyHistory: state.latencyHistory,
                    hysteresisThreshold: state.hysteresisThreshold,
                    hysteresisErrorMessage: state.hysteresisErrorMessage,
                    elapsedHistory: state.elapsedHistory,
                    gatewayDegradedThresholdMs: state.gatewayDegradedThresholdMs,
                    gatewayDegradedThresholdErrorMessage: state.gatewayDegradedThresholdErrorMessage,
                    elapsedDegradedThresholdMs: state.elapsedDegradedThresholdMs,
                    elapsedDegradedThresholdErrorMessage: state.elapsedDegradedThresholdErrorMessage,
                    gatewayDegradedBadlyThresholdMs: state.gatewayDegradedBadlyThresholdMs,
                    gatewayDegradedBadlyThresholdErrorMessage: state.gatewayDegradedBadlyThresholdErrorMessage,
                    elapsedDegradedBadlyThresholdMs: state.elapsedDegradedBadlyThresholdMs,
                    elapsedDegradedBadlyThresholdErrorMessage: "Minimum elapsed badly threshold is \(Int(minimum))ms"
                ),
                nil
            )
        }
    }

    // MARK: - Private

    private func classifyGateway(latencyMs: Double?, threshold: Double) -> Domain.ProbeResult {
        guard let latencyMs else { return .failing }
        return latencyMs > threshold ? .slow : .ok
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

    /// AC-04/AC-04b: a candidate only becomes the displayed health state after
    /// `state.hysteresisThreshold` consecutive cycles report it (ADR-0005 — hysteresis on the
    /// already-combined candidate; a threshold of 1 disables debouncing entirely).
    private func reduceCycleCompleted(
        state: Domain.State,
        gatewayLatencyMs: Double?,
        external: Domain.ProbeResult,
        elapsedMs: Double
    ) -> Domain.State {
        let gatewayResult = classifyGateway(latencyMs: gatewayLatencyMs, threshold: state.gatewayDegradedThresholdMs)
        var candidate = combine(gateway: gatewayResult, external: external)
        // Cycle time can only downgrade an otherwise-good candidate to degraded; it never
        // overrides an already-worse candidate (that's gateway/external's call to make).
        if candidate == .good && elapsedMs > state.elapsedDegradedThresholdMs {
            candidate = .degraded
        }
        // A degraded candidate escalates further to badlyDegraded when either metric crosses its
        // own (worse) threshold; never overrides an already-unreachable candidate.
        if candidate == .degraded {
            let gatewayBadly = (gatewayLatencyMs ?? 0) > state.gatewayDegradedBadlyThresholdMs
            let elapsedBadly = elapsedMs > state.elapsedDegradedBadlyThresholdMs
            if gatewayBadly || elapsedBadly {
                candidate = .badlyDegraded
            }
        }

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

        if newPendingCount >= state.hysteresisThreshold {
            newHealthState = candidate
            newPendingCandidate = nil
            newPendingCount = 0
        }

        var newLatencyHistory = state.latencyHistory
        newLatencyHistory.append(gatewayLatencyMs)
        if newLatencyHistory.count > Domain.latencyHistoryLimit {
            newLatencyHistory.removeFirst(newLatencyHistory.count - Domain.latencyHistoryLimit)
        }

        var newElapsedHistory = state.elapsedHistory
        newElapsedHistory.append(elapsedMs)
        if newElapsedHistory.count > Domain.latencyHistoryLimit {
            newElapsedHistory.removeFirst(newElapsedHistory.count - Domain.latencyHistoryLimit)
        }

        return Domain.State(
            healthState: newHealthState,
            gatewayResult: gatewayResult,
            externalResult: external,
            probeInterval: state.probeInterval,
            errorMessage: state.errorMessage,
            pendingCandidate: newPendingCandidate,
            pendingCount: newPendingCount,
            latencyHistory: newLatencyHistory,
            hysteresisThreshold: state.hysteresisThreshold,
            hysteresisErrorMessage: state.hysteresisErrorMessage,
            elapsedHistory: newElapsedHistory,
            gatewayDegradedThresholdMs: state.gatewayDegradedThresholdMs,
            gatewayDegradedThresholdErrorMessage: state.gatewayDegradedThresholdErrorMessage,
            elapsedDegradedThresholdMs: state.elapsedDegradedThresholdMs,
            elapsedDegradedThresholdErrorMessage: state.elapsedDegradedThresholdErrorMessage,
            gatewayDegradedBadlyThresholdMs: state.gatewayDegradedBadlyThresholdMs,
            gatewayDegradedBadlyThresholdErrorMessage: state.gatewayDegradedBadlyThresholdErrorMessage,
            elapsedDegradedBadlyThresholdMs: state.elapsedDegradedBadlyThresholdMs,
            elapsedDegradedBadlyThresholdErrorMessage: state.elapsedDegradedBadlyThresholdErrorMessage
        )
    }
}
