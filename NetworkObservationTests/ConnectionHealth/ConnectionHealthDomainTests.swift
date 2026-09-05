//
//  ConnectionHealthDomainTests.swift
//  NetworkObservationTests
//

import Testing
@testable import NetworkObservation

struct ConnectionHealthDomainTests {

    @Test func healthStateModelsAllFiveCasesExhaustively() {
        let all = Set(ConnectionHealthDomain.HealthState.allCases)
        let expected: Set<ConnectionHealthDomain.HealthState> = [.good, .degraded, .unreachable, .permissionNeeded, .noNetwork]
        #expect(all == expected)
        #expect(all.count == 5)
    }

    @Test func probeResultModelsAllThreeCasesExhaustively() {
        let all = Set(ConnectionHealthDomain.ProbeResult.allCases)
        let expected: Set<ConnectionHealthDomain.ProbeResult> = [.ok, .slow, .failing]
        #expect(all == expected)
        #expect(all.count == 3)
    }

    @Test func initialStateStartsWithNoResultsAndNoNetworkIsNotTheDefault() {
        let state = ConnectionHealthDomain.State.initial
        #expect(state.healthState == .good)
        #expect(state.gatewayResult == nil)
        #expect(state.externalResult == nil)
        #expect(state.errorMessage == nil)
    }
}
