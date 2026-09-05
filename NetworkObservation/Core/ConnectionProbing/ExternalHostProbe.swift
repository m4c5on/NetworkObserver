//
//  ExternalHostProbe.swift
//  NetworkObservation
//
//  Bare TCP+TLS handshake, no HTTP request (ADR-0004 Option 1) — never ICMP, per spec §6.1.
//

import Foundation
import Network

struct ExternalHostProbe {
    typealias ProbeResult = ConnectionHealthDomain.ProbeResult

    let host: String
    let port: UInt16
    let timeout: TimeInterval

    /// AC-08 classifies external results as ok/slow/failing, but only AC-06 gives a spec
    /// number (100ms, for the gateway). No external "slow" threshold is specified anywhere in
    /// spec/design — this default is this implementation's own assumption, a plain config
    /// constant per sad.md §4's "one-line edit, not a rework" precedent for such values.
    let slowThresholdMs: Double

    init(host: String = "1.1.1.1", port: UInt16 = 443, timeout: TimeInterval = 3, slowThresholdMs: Double = 300) {
        self.host = host
        self.port = port
        self.timeout = timeout
        self.slowThresholdMs = slowThresholdMs
    }

    func probe() async -> ProbeResult {
        let host = host
        let port = port
        let timeout = timeout
        let slowThresholdMs = slowThresholdMs

        return await withCheckedContinuation { continuation in
            let params = NWParameters(tls: .init(), tcp: .init())
            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: NWEndpoint.Port(integerLiteral: port),
                using: params
            )

            let queue = DispatchQueue(label: "external-host-probe")
            let start = DispatchTime.now()
            let resultLock = NSLock()
            var didFinish = false

            func finish(_ result: ProbeResult) {
                resultLock.lock()
                let alreadyFinished = didFinish
                didFinish = true
                resultLock.unlock()
                guard !alreadyFinished else { return }
                connection.cancel()
                continuation.resume(returning: result)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let elapsedMs = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                    finish(elapsedMs > slowThresholdMs ? .slow : .ok)
                case .failed, .cancelled:
                    finish(.failing)
                default:
                    break
                }
            }

            connection.start(queue: queue)

            queue.asyncAfter(deadline: .now() + timeout) {
                finish(.failing)
            }
        }
    }
}
