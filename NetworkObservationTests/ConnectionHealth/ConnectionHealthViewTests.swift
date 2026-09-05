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

    @Test func goodDegradedUnreachableAndNoNetworkAreFourDistinctColors() {
        let good = HealthState.good.statusBarColor
        let degraded = HealthState.degraded.statusBarColor
        let unreachable = HealthState.unreachable.statusBarColor
        let noNetwork = HealthState.noNetwork.statusBarColor

        #expect(good != degraded)
        #expect(good != unreachable)
        #expect(good != noNetwork)
        #expect(degraded != unreachable)
        #expect(degraded != noNetwork)
        #expect(unreachable != noNetwork)
    }

    @Test func permissionNeededSharesTheUnreachableColorPerAC03() {
        #expect(HealthState.permissionNeeded.statusBarColor == HealthState.unreachable.statusBarColor)
    }

    @Test func permissionNeededHasExplanatoryMenuTextDistinctFromUnreachable() {
        #expect(HealthState.permissionNeeded.menuExplanation != HealthState.unreachable.menuExplanation)
        #expect(HealthState.permissionNeeded.menuExplanation.isEmpty == false)
    }

    @Test func noNetworkHasExplanatoryMenuTextDistinctFromUnreachable() {
        #expect(HealthState.noNetwork.menuExplanation != HealthState.unreachable.menuExplanation)
    }

    @Test func badlyDegradedSharesTheUnreachableColor() {
        #expect(HealthState.badlyDegraded.statusBarColor == HealthState.unreachable.statusBarColor)
    }

    @Test func badlyDegradedHasExplanatoryMenuTextDistinctFromUnreachableAndDegraded() {
        #expect(HealthState.badlyDegraded.menuExplanation != HealthState.unreachable.menuExplanation)
        #expect(HealthState.badlyDegraded.menuExplanation != HealthState.degraded.menuExplanation)
    }
}
