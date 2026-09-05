//
//  GatewayProbeTests.swift
//  NetworkObservationTests
//

import Testing
@testable import NetworkObservation

struct GatewayProbeTests {

    @Test func probingLoopbackReportsReachableWithALatency() async {
        let probe = GatewayProbe(timeout: 2)
        let result = await probe.probe(host: "127.0.0.1")
        #expect(result.reachable == true)
        #expect(result.latencyMs != nil)
        if let latencyMs = result.latencyMs {
            #expect(latencyMs >= 0)
            #expect(latencyMs < 2000)
        }
    }

    @Test func probingAnUnreachableTestNetHostReportsUnreachableWithinTheTimeout() async {
        let probe = GatewayProbe(timeout: 1)
        let start = ContinuousClock.now
        let result = await probe.probe(host: "192.0.2.1") // TEST-NET-1, RFC 5737 — never routed
        let elapsed = ContinuousClock.now - start
        #expect(result.reachable == false)
        #expect(result.latencyMs == nil)
        // Generous bound (well above the 1s probe timeout) to absorb scheduler jitter under
        // parallel test execution — this only guards against an indefinite hang, not precision.
        #expect(elapsed < .seconds(10))
    }
}
