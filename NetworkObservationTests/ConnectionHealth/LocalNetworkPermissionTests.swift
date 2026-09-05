//
//  LocalNetworkPermissionTests.swift
//  NetworkObservationTests
//

import Testing
import Network
@testable import NetworkObservation

struct LocalNetworkPermissionTests {

    // MARK: - Pure state-to-signal mapping (AC-03/AC-03b), zero-mock

    @Test func readyStateMeansGranted() {
        #expect(LocalNetworkPermission.result(for: .ready) == .granted)
    }

    @Test func cancelledStateMeansPermissionNeeded() {
        #expect(LocalNetworkPermission.result(for: .cancelled) == .needed)
    }

    @Test func setupAndWaitingStatesAreNotYetDecided() {
        #expect(LocalNetworkPermission.result(for: .setup) == nil)
    }

    // MARK: - Real trigger (integration — depends on this machine's Local Network TCC state)

    @Test func checkingPermissionOnThisDevelopmentMachineReturnsGranted() async {
        // This machine already granted Local Network access to this bundle id during the T2
        // spike; a fresh install/CI machine without that prior grant would instead see .needed
        // (or hang until the operator responds to the OS prompt) — NON-red/environment-dependent
        // by nature of the OS permission model, not something this test can fully control.
        let result = await LocalNetworkPermission.checkPermission(timeout: 5)
        #expect(result == .granted)
    }

    @Test func checkingPermissionNeverHangsPastItsTimeout() async {
        let start = ContinuousClock.now
        _ = await LocalNetworkPermission.checkPermission(timeout: 3)
        let elapsed = ContinuousClock.now - start
        #expect(elapsed < .seconds(10))
    }
}
