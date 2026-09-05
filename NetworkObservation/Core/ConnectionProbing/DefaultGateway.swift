//
//  DefaultGateway.swift
//  NetworkObservation
//
//  Resolves the OS's default-route gateway IPv4 address for GatewayProbe (spec §3: only the
//  default route is evaluated, not every active interface).
//

import Foundation
import SystemConfiguration

enum DefaultGateway {
    static func ipv4Address() -> String? {
        guard let store = SCDynamicStoreCreate(nil, "NetworkObservation" as CFString, nil, nil) else {
            return nil
        }
        guard let info = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any] else {
            return nil
        }
        return info["Router"] as? String
    }
}
