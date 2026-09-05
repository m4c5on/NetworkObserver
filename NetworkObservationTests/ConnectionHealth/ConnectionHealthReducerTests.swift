//
//  ConnectionHealthReducerTests.swift
//  NetworkObservationTests
//

import Testing
@testable import NetworkObservation

struct ConnectionHealthReducerTests {

    typealias Domain = ConnectionHealthDomain
    let reducer = ConnectionHealthReducer()

    // MARK: - AC-06: 50ms gateway threshold mapping

    @Test func gatewayLatencyAtOrBelow50msClassifiesAsOk() {
        let (state, _) = reducer.reduce(state: .initial, intent: ._cycleCompleted(gatewayLatencyMs: 50, external: .ok, elapsedMs: 0))
        #expect(state.gatewayResult == .ok)
    }

    @Test func gatewayLatencyAbove50msClassifiesAsSlow() {
        let (state, _) = reducer.reduce(state: .initial, intent: ._cycleCompleted(gatewayLatencyMs: 50.1, external: .ok, elapsedMs: 0))
        #expect(state.gatewayResult == .slow)
    }

    @Test func gatewayNilLatencyClassifiesAsFailing() {
        let (state, _) = reducer.reduce(state: .initial, intent: ._cycleCompleted(gatewayLatencyMs: nil, external: .ok, elapsedMs: 0))
        #expect(state.gatewayResult == .failing)
    }

    // MARK: - AC-08: 9 gateway x external combinations (candidate, pre-hysteresis)
    // Drive the candidate to the confirmed state directly by feeding it 3 consecutive times
    // (matching the spec's "reaches display only after 3 consecutive cycles" wording, AC-04).

    static let combinations: [(gateway: Double?, external: Domain.ProbeResult, expected: Domain.HealthState)] = [
        (25, .ok, .good),
        (25, .slow, .degraded),
        (25, .failing, .unreachable),
        (75, .ok, .degraded),
        (75, .slow, .degraded),
        (75, .failing, .unreachable),
        (nil, .ok, .unreachable),
        (nil, .slow, .unreachable),
        (nil, .failing, .unreachable),
    ]

    @Test(arguments: combinations)
    func ac08CombinationTable(_ combo: (gateway: Double?, external: Domain.ProbeResult, expected: Domain.HealthState)) {
        var state = Domain.State.initial
        for _ in 0..<3 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: combo.gateway, external: combo.external, elapsedMs: 0))
        }
        #expect(state.healthState == combo.expected)
    }

    // MARK: - AC-04: hysteresis, worsening direction

    @Test func singleWorseCycleDoesNotTransition() {
        var state = Domain.State.initial // good
        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .slow, elapsedMs: 0)) // candidate: degraded
        #expect(state.healthState == .good)
    }

    @Test func twoConsecutiveWorseCyclesStillDoNotTransition() {
        var state = Domain.State.initial
        for _ in 0..<2 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .slow, elapsedMs: 0))
        }
        #expect(state.healthState == .good)
    }

    @Test func threeConsecutiveWorseCyclesTransitions() {
        var state = Domain.State.initial
        for _ in 0..<3 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .slow, elapsedMs: 0))
        }
        #expect(state.healthState == .degraded)
    }

    @Test func midStreakFlipResetsTheConsecutiveCount() {
        var state = Domain.State.initial // good
        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .slow, elapsedMs: 0)) // candidate degraded, count=1
        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .slow, elapsedMs: 0)) // count=2
        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .ok, elapsedMs: 0)) // candidate flips to good — resets
        #expect(state.healthState == .good)
        // Two more degraded cycles should NOT be enough to transition (count restarted at 1, not 3)
        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .slow, elapsedMs: 0))
        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .slow, elapsedMs: 0))
        #expect(state.healthState == .good)
    }

    // MARK: - AC-04b: hysteresis, recovery direction (symmetric)

    @Test func recoveryAlsoRequiresThreeConsecutiveBetterCycles() {
        var state = Domain.State.initial
        for _ in 0..<3 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .failing, elapsedMs: 0))
        }
        #expect(state.healthState == .unreachable)

        // Single good cycle: must not recover yet
        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .ok, elapsedMs: 0))
        #expect(state.healthState == .unreachable)

        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .ok, elapsedMs: 0))
        #expect(state.healthState == .unreachable)

        (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .ok, elapsedMs: 0))
        #expect(state.healthState == .good)
    }

    // MARK: - elapsedMs: cycle time can downgrade good to degraded, but never past it

    @Test func elapsedMsAtOrBelow100msDoesNotDowngradeGood() {
        var state = Domain.State.initial
        for _ in 0..<3 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .ok, elapsedMs: 100))
        }
        #expect(state.healthState == .good)
    }

    @Test func elapsedMsAbove100msDowngradesGoodToDegraded() {
        var state = Domain.State.initial
        for _ in 0..<3 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .ok, elapsedMs: 150))
        }
        #expect(state.healthState == .degraded)
    }

    @Test func elapsedMsAboveThresholdDoesNotEscalatePastDegradedWhenAlreadyUnreachable() {
        var state = Domain.State.initial
        for _ in 0..<3 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: nil, external: .ok, elapsedMs: 5000))
        }
        #expect(state.healthState == .unreachable)
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

    // MARK: - plain threshold accepted/rejected (post-validation, driven by Settings)

    @Test func gatewayDegradedThresholdAcceptedUpdatesStateAndClearsAnyPriorError() {
        var state = Domain.State.initial
        (state, _) = reducer.reduce(state: state, intent: ._gatewayDegradedThresholdRejected(minimum: 1))
        #expect(state.gatewayDegradedThresholdErrorMessage != nil)
        let (newState, _) = reducer.reduce(state: state, intent: ._gatewayDegradedThresholdAccepted(75))
        #expect(newState.gatewayDegradedThresholdMs == 75)
        #expect(newState.gatewayDegradedThresholdErrorMessage == nil)
    }

    @Test func elapsedDegradedThresholdAcceptedUpdatesStateAndClearsAnyPriorError() {
        var state = Domain.State.initial
        (state, _) = reducer.reduce(state: state, intent: ._elapsedDegradedThresholdRejected(minimum: 1))
        #expect(state.elapsedDegradedThresholdErrorMessage != nil)
        let (newState, _) = reducer.reduce(state: state, intent: ._elapsedDegradedThresholdAccepted(150))
        #expect(newState.elapsedDegradedThresholdMs == 150)
        #expect(newState.elapsedDegradedThresholdErrorMessage == nil)
    }

    // MARK: - badlyDegraded: a degraded candidate escalates further past either badly threshold

    @Test func gatewayAtOrBelowBadlyThresholdStaysDegraded() {
        var state = Domain.State.initial
        for _ in 0..<3 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: state.gatewayDegradedBadlyThresholdMs, external: .ok, elapsedMs: 0))
        }
        #expect(state.healthState == .degraded)
    }

    @Test func gatewayAboveBadlyThresholdEscalatesToBadlyDegraded() {
        var state = Domain.State.initial
        let badly = state.gatewayDegradedBadlyThresholdMs
        for _ in 0..<3 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: badly + 0.1, external: .ok, elapsedMs: 0))
        }
        #expect(state.healthState == .badlyDegraded)
    }

    @Test func elapsedAtOrBelowBadlyThresholdStaysDegraded() {
        var state = Domain.State.initial
        for _ in 0..<3 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .ok, elapsedMs: state.elapsedDegradedBadlyThresholdMs))
        }
        #expect(state.healthState == .degraded)
    }

    @Test func elapsedAboveBadlyThresholdEscalatesToBadlyDegraded() {
        var state = Domain.State.initial
        let badly = state.elapsedDegradedBadlyThresholdMs
        for _ in 0..<3 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: 10, external: .ok, elapsedMs: badly + 0.1))
        }
        #expect(state.healthState == .badlyDegraded)
    }

    @Test func badlyThresholdsNeverEscalatePastAnAlreadyUnreachableCandidate() {
        var state = Domain.State.initial
        for _ in 0..<3 {
            (state, _) = reducer.reduce(state: state, intent: ._cycleCompleted(gatewayLatencyMs: nil, external: .ok, elapsedMs: 999_999))
        }
        #expect(state.healthState == .unreachable)
    }

    // MARK: - badly threshold accepted/rejected (post-validation, driven by Settings)

    @Test func gatewayDegradedBadlyThresholdAcceptedUpdatesStateAndClearsAnyPriorError() {
        var state = Domain.State.initial
        (state, _) = reducer.reduce(state: state, intent: ._gatewayDegradedBadlyThresholdRejected(minimum: 100))
        #expect(state.gatewayDegradedBadlyThresholdErrorMessage != nil)
        let (newState, _) = reducer.reduce(state: state, intent: ._gatewayDegradedBadlyThresholdAccepted(500))
        #expect(newState.gatewayDegradedBadlyThresholdMs == 500)
        #expect(newState.gatewayDegradedBadlyThresholdErrorMessage == nil)
    }

    @Test func elapsedDegradedBadlyThresholdAcceptedUpdatesStateAndClearsAnyPriorError() {
        var state = Domain.State.initial
        (state, _) = reducer.reduce(state: state, intent: ._elapsedDegradedBadlyThresholdRejected(minimum: 300))
        #expect(state.elapsedDegradedBadlyThresholdErrorMessage != nil)
        let (newState, _) = reducer.reduce(state: state, intent: ._elapsedDegradedBadlyThresholdAccepted(1000))
        #expect(newState.elapsedDegradedBadlyThresholdMs == 1000)
        #expect(newState.elapsedDegradedBadlyThresholdErrorMessage == nil)
    }

    // MARK: - user-configurable health-tier colors (no accept/reject: any color is valid)

    @Test func goodColorChangedUpdatesStateAndPersists() {
        let (newState, effect) = reducer.reduce(state: .initial, intent: .goodColorChanged("#123456"))
        #expect(newState.goodColorHex == "#123456")
        guard case .persistGoodColor(let hex) = effect else {
            Issue.record("expected a persistGoodColor effect")
            return
        }
        #expect(hex == "#123456")
    }

    @Test func degradedColorChangedUpdatesStateAndPersists() {
        let (newState, effect) = reducer.reduce(state: .initial, intent: .degradedColorChanged("#654321"))
        #expect(newState.degradedColorHex == "#654321")
        guard case .persistDegradedColor(let hex) = effect else {
            Issue.record("expected a persistDegradedColor effect")
            return
        }
        #expect(hex == "#654321")
    }

    @Test func badColorChangedUpdatesStateAndPersists() {
        let (newState, effect) = reducer.reduce(state: .initial, intent: .badColorChanged("#ABCDEF"))
        #expect(newState.badColorHex == "#ABCDEF")
        guard case .persistBadColor(let hex) = effect else {
            Issue.record("expected a persistBadColor effect")
            return
        }
        #expect(hex == "#ABCDEF")
    }

    @Test func changingOneColorLeavesTheOtherTwoUntouched() {
        let (newState, _) = reducer.reduce(state: .initial, intent: .goodColorChanged("#123456"))
        #expect(newState.degradedColorHex == Domain.State.initial.degradedColorHex)
        #expect(newState.badColorHex == Domain.State.initial.badColorHex)
    }
}
