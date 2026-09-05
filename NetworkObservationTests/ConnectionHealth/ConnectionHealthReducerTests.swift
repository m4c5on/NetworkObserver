//
//  ConnectionHealthReducerTests.swift
//  NetworkObservationTests
//

import Testing
@testable import NetworkObservation

struct ConnectionHealthReducerTests {

    typealias Domain = ConnectionHealthDomain
    let reducer = ConnectionHealthReducer()

    // MARK: - AC-06: 100ms gateway threshold mapping

    @Test func gatewayLatencyAtOrBelow100msClassifiesAsOk() {
        let (state, _) = reducer.reduce(state: .initial, intent: ._cycleCompleted(gatewayLatencyMs: 100, external: .ok))
        #expect(state.gatewayResult == .ok)
    }

    @Test func gatewayLatencyAbove100msClassifiesAsSlow() {
        let (state, _) = reducer.reduce(state: .initial, intent: ._cycleCompleted(gatewayLatencyMs: 100.1, external: .ok))
        #expect(state.gatewayResult == .slow)
    }

    @Test func gatewayNilLatencyClassifiesAsFailing() {
        let (state, _) = reducer.reduce(state: .initial, intent: ._cycleCompleted(gatewayLatencyMs: nil, external: .ok))
        #expect(state.gatewayResult == .failing)
    }

    // MARK: - AC-08: 9 gateway x external combinations (candidate, pre-hysteresis)
    // Drive the candidate to the confirmed state directly by feeding it 3 consecutive times
    // (matching the spec's "reaches display only after 3 consecutive cycles" wording, AC-04).

    static let combinations: [(gateway: Double?, external: Domain.ProbeResult, expected: Domain.HealthState)] = [
        (50, .ok, .good),
        (50, .slow, .degraded),
        (50, .failing, .unreachable),
        (150, .ok, .degraded),
        (150, .slow, .degraded),
        (150, .failing, .unreachable),
        (nil, .ok, .unreachable),
        (nil, .slow, .unreachable),
        (nil, .failing, .unreachable),
    ]

    @Test(arguments: combinations)
    func ac08CombinationTable(_ combo: (gateway: Double?, external: Domain.ProbeResult, expected: Domain.HealthState)) {
        var state = Domain.State.initial
        for _ in 0..<3 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: combo.gateway, external: combo.external))
        }
        #expect(state.healthState == combo.expected)
    }

    // MARK: - AC-04: hysteresis, worsening direction

    @Test func singleWorseCycleDoesNotTransition() {
        var state = Domain.State.initial // good
        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 50, external: .slow)) // candidate: degraded
        #expect(state.healthState == .good)
    }

    @Test func twoConsecutiveWorseCyclesStillDoNotTransition() {
        var state = Domain.State.initial
        for _ in 0..<2 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 50, external: .slow))
        }
        #expect(state.healthState == .good)
    }

    @Test func threeConsecutiveWorseCyclesTransitions() {
        var state = Domain.State.initial
        for _ in 0..<3 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 50, external: .slow))
        }
        #expect(state.healthState == .degraded)
    }

    @Test func midStreakFlipResetsTheConsecutiveCount() {
        var state = Domain.State.initial // good
        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 50, external: .slow)) // candidate degraded, count=1
        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 50, external: .slow)) // count=2
        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 50, external: .ok)) // candidate flips to good — resets
        #expect(state.healthState == .good)
        // Two more degraded cycles should NOT be enough to transition (count restarted at 1, not 3)
        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 50, external: .slow))
        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 50, external: .slow))
        #expect(state.healthState == .good)
    }

    // MARK: - AC-04b: hysteresis, recovery direction (symmetric)

    @Test func recoveryAlsoRequiresThreeConsecutiveBetterCycles() {
        var state = Domain.State.initial
        for _ in 0..<3 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 50, external: .failing))
        }
        #expect(state.healthState == .unreachable)

        // Single good cycle: must not recover yet
        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 50, external: .ok))
        #expect(state.healthState == .unreachable)

        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 50, external: .ok))
        #expect(state.healthState == .unreachable)

        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 50, external: .ok))
        #expect(state.healthState == .good)
    }

    // MARK: - AC-05: interval accepted/rejected (post-validation, driven by Settings)

    @Test func intervalAcceptedUpdatesStateAndClearsAnyPriorError() {
        var state = Domain.State.initial
        (state, _) = reducer.reduce(state: state, intent: ._intervalRejected(minimum: 1))
        #expect(state.errorMessage != nil)
        let (newState, effect) = reducer.reduce(state: state, intent: ._intervalAccepted(10))
        #expect(newState.probeInterval == 10)
        #expect(newState.errorMessage == nil)
        guard case .rescheduleProbeLoop(let interval) = effect else {
            Issue.record("expected a rescheduleProbeLoop effect")
            return
        }
        #expect(interval == 10)
    }

    @Test func intervalRejectedSetsAnErrorAndKeepsThePreviousInterval() {
        let state = Domain.State.initial
        let (newState, effect) = reducer.reduce(state: state, intent: ._intervalRejected(minimum: 1))
        #expect(newState.probeInterval == state.probeInterval)
        #expect(newState.errorMessage != nil)
        #expect(effect == nil)
    }
}
