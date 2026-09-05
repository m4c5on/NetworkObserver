//
//  ConnectionHealthSettings.swift
//  NetworkObservation
//
//  AC-05 — probe interval persistence + the enforced minimum floor.
//

import Foundation

struct ConnectionHealthSettings {
    static let minimumProbeInterval: TimeInterval = 0.1
    static let defaultProbeInterval: TimeInterval = 5

    /// AC-04/AC-04b hysteresis: how many consecutive cycles a candidate must hold before it
    /// becomes the displayed health state. 1 disables debouncing entirely.
    static let minimumHysteresisThreshold = 1
    static let defaultHysteresisThreshold = 3

    private static let probeIntervalKey = "probeInterval"
    private static let hysteresisThresholdKey = "hysteresisThreshold"

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

    var hysteresisThreshold: Int {
        let stored = defaults.integer(forKey: Self.hysteresisThresholdKey)
        return stored >= Self.minimumHysteresisThreshold ? stored : Self.defaultHysteresisThreshold
    }

    /// Rejects a candidate below the enforced minimum, keeping the previous valid threshold in
    /// effect — returns whether the candidate was accepted.
    @discardableResult
    func setHysteresisThreshold(_ candidate: Int) -> Bool {
        guard candidate >= Self.minimumHysteresisThreshold else { return false }
        defaults.set(candidate, forKey: Self.hysteresisThresholdKey)
        return true
    }
}
