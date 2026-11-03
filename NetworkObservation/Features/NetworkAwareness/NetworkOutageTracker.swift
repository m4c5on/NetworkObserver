//
//  NetworkOutageTracker.swift
//  NetworkObservation
//
//  Decides when this Mac has lost / regained the internet, from the connection-health state.
//  Drives the "internet lost/restored" notifications and the site checks' paused banner.
//

import Foundation

enum NetworkOutageEvent: Equatable {
    case wentDown
    case cameBack(downtime: TimeInterval)

    var isNetworkAvailable: Bool {
        if case .cameBack = self { true } else { false }
    }
}

struct NetworkOutageTracker {
    private var downSince: Date?

    /// An outage starts when there is no network interface, or when the (debounced) health state
    /// is unreachable *and* the internet probe itself fails — a router that merely ignores pings
    /// is not an outage. It ends only when the debounced health state leaves unreachable/no
    /// network, so one good probe cycle in the middle of an outage does not end it.
    mutating func register(
        healthState: ConnectionHealthDomain.HealthState,
        externalResult: ConnectionHealthDomain.ProbeResult?,
        at date: Date
    ) -> NetworkOutageEvent? {
        if let downSince {
            guard healthState != .unreachable, healthState != .noNetwork else { return nil }
            self.downSince = nil
            return .cameBack(downtime: date.timeIntervalSince(downSince))
        }

        let isDown = healthState == .noNetwork || (healthState == .unreachable && externalResult == .failing)
        guard isDown else { return nil }
        downSince = date
        return .wentDown
    }
}
