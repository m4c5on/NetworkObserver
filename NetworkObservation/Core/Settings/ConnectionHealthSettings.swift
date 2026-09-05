//
//  ConnectionHealthSettings.swift
//  NetworkObservation
//
//  AC-05 — probe interval persistence + the enforced minimum floor.
//

import Foundation

struct ConnectionHealthSettings {
    static let minimumProbeInterval: TimeInterval = 1
    static let defaultProbeInterval: TimeInterval = 5

    private static let probeIntervalKey = "probeInterval"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var probeInterval: TimeInterval {
        let stored = defaults.double(forKey: Self.probeIntervalKey)
        return stored >= Self.minimumProbeInterval ? stored : Self.defaultProbeInterval
    }

    /// Rejects a candidate below the enforced minimum, keeping the previous valid interval in
    /// effect (AC-05) — returns whether the candidate was accepted.
    @discardableResult
    func setProbeInterval(_ candidate: TimeInterval) -> Bool {
        guard candidate >= Self.minimumProbeInterval else { return false }
        defaults.set(candidate, forKey: Self.probeIntervalKey)
        return true
    }
}
