//
//  NetworkInterfaceMonitor.swift
//  NetworkObservation
//
//  AC-07 — detects the absence of any active network interface, distinct from a probe timeout.
//

import Foundation

struct NetworkInterfaceMonitor {
    struct Interface: Equatable {
        let name: String
        let isUp: Bool
        let isRunning: Bool
        let isLoopback: Bool
    }

    /// Pure decision: at least one non-loopback interface that is both up and running.
    static func hasActiveInterface(among interfaces: [Interface]) -> Bool {
        interfaces.contains { $0.isUp && $0.isRunning && !$0.isLoopback }
    }

    func hasActiveInterface() -> Bool {
        Self.hasActiveInterface(among: Self.currentInterfaces())
    }

    private static func currentInterfaces() -> [Interface] {
        var result: [Interface] = []
        var ifaddrPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPointer) == 0, let firstAddr = ifaddrPointer else { return [] }
        defer { freeifaddrs(ifaddrPointer) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = cursor {
            let flags = Int32(current.pointee.ifa_flags)
            let name = String(cString: current.pointee.ifa_name)
            result.append(
                Interface(
                    name: name,
                    isUp: (flags & IFF_UP) != 0,
                    isRunning: (flags & IFF_RUNNING) != 0,
                    isLoopback: (flags & IFF_LOOPBACK) != 0
                )
            )
            cursor = current.pointee.ifa_next
        }
        return result
    }
}
