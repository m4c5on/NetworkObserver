//
//  LocalNetworkPermission.swift
//  NetworkObservation
//
//  AC-03/AC-03b — a short-lived NWBrowser trigger both raises the OS's Local Network
//  permission prompt and is read as the permission signal (ADR-0003), decoupled from the
//  real probes so "no permission" and "gateway down" never conflate.
//

import Foundation
import Network

enum LocalNetworkPermission {
    enum Result: Equatable {
        case granted
        case needed
    }

    /// Pure mapping from an NWBrowser state to the permission signal — `nil` means "not decided
    /// yet, keep waiting" (ADR-0003's confirmed mechanism: `.ready` after Allow, `.failed`/
    /// `.cancelled` when denied or torn down).
    static func result(for state: NWBrowser.State) -> Result? {
        switch state {
        case .ready:
            return .granted
        case .failed, .cancelled:
            return .needed
        default:
            return nil
        }
    }

    static func checkPermission(timeout: TimeInterval = 5) async -> Result {
        await withCheckedContinuation { continuation in
            let params = NWParameters()
            params.includePeerToPeer = true
            let browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: params)

            let queue = DispatchQueue(label: "local-network-permission")
            let lock = NSLock()
            var didFinish = false

            func finish(_ result: Result) {
                lock.lock()
                let alreadyFinished = didFinish
                didFinish = true
                lock.unlock()
                guard !alreadyFinished else { return }
                browser.cancel()
                continuation.resume(returning: result)
            }

            browser.stateUpdateHandler = { state in
                if let result = Self.result(for: state) {
                    finish(result)
                }
            }

            browser.start(queue: queue)

            queue.asyncAfter(deadline: .now() + timeout) {
                finish(.needed)
            }
        }
    }
}
