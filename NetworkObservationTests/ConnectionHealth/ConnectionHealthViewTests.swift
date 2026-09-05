//
//  ConnectionHealthViewTests.swift
//  NetworkObservationTests
//
//  Pure view-mapping logic (color/symbol per state, breakdown text). Interactive UI automation
//  of the actual status-bar item is out of scope per test-plan.md's E2E-through-UI note (a
//  manual smoke checklist, not automated); these tests cover everything about the mapping that
//  can be exercised without driving the real menu-bar item.
//

import Testing
import SwiftUI
@testable import NetworkObservation

struct ConnectionHealthViewTests {

    typealias HealthState = ConnectionHealthDomain.HealthState

    private let good = Color.red
    private let degraded = Color.orange
    private let bad = Color.purple

    @Test func goodDegradedUnreachableAndNoNetworkAreFourDistinctColors() {
        let goodResolved = HealthState.good.statusBarColor(good: good, degraded: degraded, bad: bad)
        let degradedResolved = HealthState.degraded.statusBarColor(good: good, degraded: degraded, bad: bad)
        let unreachableResolved = HealthState.unreachable.statusBarColor(good: good, degraded: degraded, bad: bad)
        let noNetworkResolved = HealthState.noNetwork.statusBarColor(good: good, degraded: degraded, bad: bad)

        #expect(goodResolved != degradedResolved)
        #expect(goodResolved != unreachableResolved)
        #expect(goodResolved != noNetworkResolved)
        #expect(degradedResolved != unreachableResolved)
        #expect(degradedResolved != noNetworkResolved)
        #expect(unreachableResolved != noNetworkResolved)
    }

    @Test func permissionNeededSharesTheUnreachableColorPerAC03() {
        #expect(HealthState.permissionNeeded.statusBarColor(good: good, degraded: degraded, bad: bad) == HealthState.unreachable.statusBarColor(good: good, degraded: degraded, bad: bad))
    }

    @Test func permissionNeededHasExplanatoryMenuTextDistinctFromUnreachable() {
        #expect(HealthState.permissionNeeded.menuExplanation != HealthState.unreachable.menuExplanation)
        #expect(HealthState.permissionNeeded.menuExplanation.isEmpty == false)
    }

    @Test func noNetworkHasExplanatoryMenuTextDistinctFromUnreachable() {
        #expect(HealthState.noNetwork.menuExplanation != HealthState.unreachable.menuExplanation)
    }

    @Test func badlyDegradedSharesTheUnreachableColor() {
        #expect(HealthState.badlyDegraded.statusBarColor(good: good, degraded: degraded, bad: bad) == HealthState.unreachable.statusBarColor(good: good, degraded: degraded, bad: bad))
    }

    @Test func badlyDegradedHasExplanatoryMenuTextDistinctFromUnreachableAndDegraded() {
        #expect(HealthState.badlyDegraded.menuExplanation != HealthState.unreachable.menuExplanation)
        #expect(HealthState.badlyDegraded.menuExplanation != HealthState.degraded.menuExplanation)
    }

    // MARK: - Color <-> hex bridge (ConnectionHealthSettings persists colors as hex strings)

    @Test func hexInitializerDecodesAKnownColor() {
        let color = Color(hex: "#A3D9A5")
        #expect(color != nil)
        #expect(color?.hexString == "#A3D9A5")
    }

    @Test func hexInitializerAcceptsALowercaseHexWithoutTheHashPrefix() {
        let color = Color(hex: "a3d9a5")
        #expect(color?.hexString == "#A3D9A5")
    }

    @Test func hexInitializerRejectsAnInvalidString() {
        #expect(Color(hex: "not-a-color") == nil)
    }

    @Test func stateColorFallsBackToTheDefaultWhenTheStoredHexIsUnparseable() {
        var state = ConnectionHealthDomain.State.initial
        state = ConnectionHealthDomain.State(
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
            elapsedDegradedBadlyThresholdErrorMessage: state.elapsedDegradedBadlyThresholdErrorMessage,
            goodColorHex: "garbage",
            degradedColorHex: state.degradedColorHex,
            badColorHex: state.badColorHex
        )
        #expect(state.goodColor.hexString == ConnectionHealthSettings.defaultGoodColorHex)
    }
}
