//
//  ExternalHostProbeTests.swift
//  NetworkObservationTests
//

import Testing
@testable import NetworkObservation

struct ExternalHostProbeTests {

    @Test func handshakeToTheRealExternalHostReportsOkOrSlowNeverFailing() async {
        let probe = ExternalHostProbe(host: "1.1.1.1", port: 443, timeout: 5)
        let result = await probe.probe()
        #expect(result == .ok || result == .slow)
    }

    @Test func handshakeToAnUnreachableTestNetHostReportsFailingWithinTheTimeout() async {
        // TEST-NET-1 (RFC 5737) — never routed, so the TCP SYN never completes.
        let probe = ExternalHostProbe(host: "192.0.2.1", port: 443, timeout: 2)
        let result = await probe.probe()
        #expect(result == .failing)
    }

    @Test func aFastHandshakeBelowTheThresholdClassifiesAsOk() async {
        let probe = ExternalHostProbe(host: "1.1.1.1", port: 443, timeout: 5, slowThresholdMs: 100_000)
        let result = await probe.probe()
        #expect(result == .ok)
    }

    @Test func aSlowThresholdOfZeroClassifiesAnySuccessfulHandshakeAsSlow() async {
        let probe = ExternalHostProbe(host: "1.1.1.1", port: 443, timeout: 5, slowThresholdMs: 0)
        let result = await probe.probe()
        #expect(result == .slow)
    }
}
