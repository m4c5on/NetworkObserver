//
//  ConnectionHealthSettingsTests.swift
//  NetworkObservationTests
//

import Testing
import Foundation
@testable import NetworkObservation

struct ConnectionHealthSettingsTests {

    private func makeSettings() -> ConnectionHealthSettings {
        let suiteName = "ConnectionHealthSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return ConnectionHealthSettings(defaults: defaults)
    }

    @Test func defaultsToFiveSecondsWhenNothingIsStored() {
        let settings = makeSettings()
        #expect(settings.probeInterval == 5)
    }

    @Test func aValueAtTheMinimumPersists() {
        let settings = makeSettings()
        let accepted = settings.setProbeInterval(1)
        #expect(accepted == true)
        #expect(settings.probeInterval == 1)
    }

    @Test func aValueAboveTheMinimumPersists() {
        let settings = makeSettings()
        let accepted = settings.setProbeInterval(10)
        #expect(accepted == true)
        #expect(settings.probeInterval == 10)
    }

    @Test func aValueBelowTheMinimumIsRejectedAndThePreviousValueIsRetained() {
        let settings = makeSettings()
        settings.setProbeInterval(8)
        let accepted = settings.setProbeInterval(0.5)
        #expect(accepted == false)
        #expect(settings.probeInterval == 8)
    }
}
