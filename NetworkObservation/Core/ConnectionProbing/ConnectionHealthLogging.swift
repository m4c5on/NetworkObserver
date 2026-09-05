//
//  ConnectionHealthLogging.swift
//  NetworkObservation
//
//  Local-only os_log instrumentation (T13) — probe-cycle-completion timestamps for the
//  status-update-latency NFR (spec §6 QG-3, <=250ms) and health-state transitions for
//  soak-test log analysis (QG-1/QG-4/QG-5). Never leaves the device (spec §6.1).
//

import Foundation
import os

enum ConnectionHealthLogging {
    private static let logger = Logger(subsystem: "com.msg.groceriesTracker.NetworkObservation", category: "ConnectionHealth")

    static func logCycleCompleted(elapsedMs: Double) {
        logger.log("probe-cycle-completed elapsedMs=\(elapsedMs, privacy: .public)")
    }

    static func logHealthStateTransition(
        from: ConnectionHealthDomain.HealthState,
        to: ConnectionHealthDomain.HealthState
    ) {
        logger.log("health-state-transition from=\(String(describing: from), privacy: .public) to=\(String(describing: to), privacy: .public)")
    }
}
