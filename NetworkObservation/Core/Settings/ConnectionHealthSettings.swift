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

    /// AC-06: the gateway is classified degraded above this latency.
    static let minimumGatewayDegradedThresholdMs: Double = 1
    static let defaultGatewayDegradedThresholdMs: Double = 50

    /// Cycle time above which an otherwise-`.good` candidate is downgraded to `.degraded`.
    static let minimumElapsedDegradedThresholdMs: Double = 1
    static let defaultElapsedDegradedThresholdMs: Double = 100

    static let minimumGatewayDegradedBadlyThresholdMs: Double = 1
    static let defaultGatewayDegradedBadlyThresholdMs: Double = 100

    static let minimumElapsedDegradedBadlyThresholdMs: Double = 1
    static let defaultElapsedDegradedBadlyThresholdMs: Double = 300

    /// User-configurable colors for the three health tiers. Any color a ColorPicker produces is
    /// valid, so there's no minimum/rejection concept here — just a default fallback.
    static let defaultGoodColorHex = "#A3D9A5"
    static let defaultDegradedColorHex = "#F7E08E"
    static let defaultBadColorHex = "#F4A9A0"

    private static let probeIntervalKey = "probeInterval"
    private static let hysteresisThresholdKey = "hysteresisThreshold"
    private static let gatewayDegradedThresholdMsKey = "gatewayDegradedThresholdMs"
    private static let elapsedDegradedThresholdMsKey = "elapsedDegradedThresholdMs"
    private static let gatewayDegradedBadlyThresholdMsKey = "gatewayDegradedBadlyThresholdMs"
    private static let elapsedDegradedBadlyThresholdMsKey = "elapsedDegradedBadlyThresholdMs"
    private static let goodColorHexKey = "goodColorHex"
    private static let degradedColorHexKey = "degradedColorHex"
    private static let badColorHexKey = "badColorHex"

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

    var gatewayDegradedThresholdMs: Double {
        let stored = defaults.double(forKey: Self.gatewayDegradedThresholdMsKey)
        return stored >= Self.minimumGatewayDegradedThresholdMs ? stored : Self.defaultGatewayDegradedThresholdMs
    }

    @discardableResult
    func setGatewayDegradedThreshold(_ candidate: Double) -> Bool {
        guard candidate >= Self.minimumGatewayDegradedThresholdMs else { return false }
        defaults.set(candidate, forKey: Self.gatewayDegradedThresholdMsKey)
        return true
    }

    var elapsedDegradedThresholdMs: Double {
        let stored = defaults.double(forKey: Self.elapsedDegradedThresholdMsKey)
        return stored >= Self.minimumElapsedDegradedThresholdMs ? stored : Self.defaultElapsedDegradedThresholdMs
    }

    @discardableResult
    func setElapsedDegradedThreshold(_ candidate: Double) -> Bool {
        guard candidate >= Self.minimumElapsedDegradedThresholdMs else { return false }
        defaults.set(candidate, forKey: Self.elapsedDegradedThresholdMsKey)
        return true
    }

    var gatewayDegradedBadlyThresholdMs: Double {
        let stored = defaults.double(forKey: Self.gatewayDegradedBadlyThresholdMsKey)
        return stored >= Self.minimumGatewayDegradedBadlyThresholdMs ? stored : Self.defaultGatewayDegradedBadlyThresholdMs
    }

    @discardableResult
    func setGatewayDegradedBadlyThreshold(_ candidate: Double) -> Bool {
        guard candidate >= Self.minimumGatewayDegradedBadlyThresholdMs else { return false }
        defaults.set(candidate, forKey: Self.gatewayDegradedBadlyThresholdMsKey)
        return true
    }

    var elapsedDegradedBadlyThresholdMs: Double {
        let stored = defaults.double(forKey: Self.elapsedDegradedBadlyThresholdMsKey)
        return stored >= Self.minimumElapsedDegradedBadlyThresholdMs ? stored : Self.defaultElapsedDegradedBadlyThresholdMs
    }

    @discardableResult
    func setElapsedDegradedBadlyThreshold(_ candidate: Double) -> Bool {
        guard candidate >= Self.minimumElapsedDegradedBadlyThresholdMs else { return false }
        defaults.set(candidate, forKey: Self.elapsedDegradedBadlyThresholdMsKey)
        return true
    }

    var goodColorHex: String {
        defaults.string(forKey: Self.goodColorHexKey) ?? Self.defaultGoodColorHex
    }

    func setGoodColorHex(_ hex: String) {
        defaults.set(hex, forKey: Self.goodColorHexKey)
    }

    var degradedColorHex: String {
        defaults.string(forKey: Self.degradedColorHexKey) ?? Self.defaultDegradedColorHex
    }

    func setDegradedColorHex(_ hex: String) {
        defaults.set(hex, forKey: Self.degradedColorHexKey)
    }

    var badColorHex: String {
        defaults.string(forKey: Self.badColorHexKey) ?? Self.defaultBadColorHex
    }

    func setBadColorHex(_ hex: String) {
        defaults.set(hex, forKey: Self.badColorHexKey)
    }
}
