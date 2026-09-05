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
        let accepted = settings.setProbeInterval(0.05)
        #expect(accepted == false)
        #expect(settings.probeInterval == 8)
    }

    @Test func gatewayDegradedThresholdDefaultsToFiftyMs() {
        let settings = makeSettings()
        #expect(settings.gatewayDegradedThresholdMs == 50)
    }

    @Test func gatewayDegradedThresholdAtOrAboveTheMinimumPersists() {
        let settings = makeSettings()
        let accepted = settings.setGatewayDegradedThreshold(75)
        #expect(accepted == true)
        #expect(settings.gatewayDegradedThresholdMs == 75)
    }

    @Test func gatewayDegradedThresholdBelowTheMinimumIsRejected() {
        let settings = makeSettings()
        settings.setGatewayDegradedThreshold(75)
        let accepted = settings.setGatewayDegradedThreshold(0)
        #expect(accepted == false)
        #expect(settings.gatewayDegradedThresholdMs == 75)
    }

    @Test func elapsedDegradedThresholdDefaultsToOneHundredMs() {
        let settings = makeSettings()
        #expect(settings.elapsedDegradedThresholdMs == 100)
    }

    @Test func elapsedDegradedThresholdAtOrAboveTheMinimumPersists() {
        let settings = makeSettings()
        let accepted = settings.setElapsedDegradedThreshold(150)
        #expect(accepted == true)
        #expect(settings.elapsedDegradedThresholdMs == 150)
    }

    @Test func elapsedDegradedThresholdBelowTheMinimumIsRejected() {
        let settings = makeSettings()
        settings.setElapsedDegradedThreshold(150)
        let accepted = settings.setElapsedDegradedThreshold(0)
        #expect(accepted == false)
        #expect(settings.elapsedDegradedThresholdMs == 150)
    }

    @Test func gatewayDegradedBadlyThresholdDefaultsToOneHundredMs() {
        let settings = makeSettings()
        #expect(settings.gatewayDegradedBadlyThresholdMs == 100)
    }

    @Test func gatewayDegradedBadlyThresholdAtOrAboveTheMinimumPersists() {
        let settings = makeSettings()
        let accepted = settings.setGatewayDegradedBadlyThreshold(500)
        #expect(accepted == true)
        #expect(settings.gatewayDegradedBadlyThresholdMs == 500)
    }

    @Test func gatewayDegradedBadlyThresholdBelowTheMinimumIsRejected() {
        let settings = makeSettings()
        settings.setGatewayDegradedBadlyThreshold(500)
        let accepted = settings.setGatewayDegradedBadlyThreshold(0)
        #expect(accepted == false)
        #expect(settings.gatewayDegradedBadlyThresholdMs == 500)
    }

    @Test func elapsedDegradedBadlyThresholdDefaultsToThreeHundredMs() {
        let settings = makeSettings()
        #expect(settings.elapsedDegradedBadlyThresholdMs == 300)
    }

    @Test func elapsedDegradedBadlyThresholdAtOrAboveTheMinimumPersists() {
        let settings = makeSettings()
        let accepted = settings.setElapsedDegradedBadlyThreshold(1000)
        #expect(accepted == true)
        #expect(settings.elapsedDegradedBadlyThresholdMs == 1000)
    }

    @Test func elapsedDegradedBadlyThresholdBelowTheMinimumIsRejected() {
        let settings = makeSettings()
        settings.setElapsedDegradedBadlyThreshold(1000)
        let accepted = settings.setElapsedDegradedBadlyThreshold(0)
        #expect(accepted == false)
        #expect(settings.elapsedDegradedBadlyThresholdMs == 1000)
    }

    @Test func colorsDefaultToThePastelPaletteWhenNothingIsStored() {
        let settings = makeSettings()
        #expect(settings.goodColorHex == "#A3D9A5")
        #expect(settings.degradedColorHex == "#F7E08E")
        #expect(settings.badColorHex == "#F4A9A0")
    }

    @Test func aChosenGoodColorPersists() {
        let settings = makeSettings()
        settings.setGoodColorHex("#123456")
        #expect(settings.goodColorHex == "#123456")
    }

    @Test func aChosenDegradedColorPersists() {
        let settings = makeSettings()
        settings.setDegradedColorHex("#654321")
        #expect(settings.degradedColorHex == "#654321")
    }

    @Test func aChosenBadColorPersists() {
        let settings = makeSettings()
        settings.setBadColorHex("#ABCDEF")
        #expect(settings.badColorHex == "#ABCDEF")
    }
}
