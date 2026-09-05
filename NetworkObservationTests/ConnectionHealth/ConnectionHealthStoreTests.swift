//
//  ConnectionHealthStoreTests.swift
//  NetworkObservationTests
//

import Testing
import Foundation
import AppKit
@testable import NetworkObservation

@MainActor
struct ConnectionHealthStoreTests {

    private func makeSettings() -> ConnectionHealthSettings {
        let suiteName = "ConnectionHealthStoreTests.\(UUID().uuidString)"
        return ConnectionHealthSettings(defaults: UserDefaults(suiteName: suiteName)!)
    }

    private func waitBriefly(_ seconds: Double = 0.3) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    @Test func runsThePermissionCheckExactlyOnceAcrossMultipleCycles() async {
        actor Counter { var count = 0; func increment() { count += 1 } }
        let counter = Counter()

        let store = ConnectionHealthStore(
            reducer: ConnectionHealthReducer(),
            probeGateway: { _ in GatewayProbe.Result(reachable: true, latencyMs: 10) },
            probeExternal: { .ok },
            hasActiveInterface: { true },
            settings: makeSettings(),
            checkPermission: { _ in await counter.increment(); return .granted },
            gatewayHost: { "127.0.0.1" },
            notificationCenter: NotificationCenter(),
            probeInterval: 0.05
        )

        store.start()
        await waitBriefly(0.3)
        store.stop()

        let finalCount = await counter.count
        #expect(finalCount == 1)
    }

    @Test func whenPermissionIsNeededStateBecomesPermissionNeededAndNoProbesRun() async {
        actor Counter { var count = 0; func increment() { count += 1 } }
        let probeCounter = Counter()

        let store = ConnectionHealthStore(
            reducer: ConnectionHealthReducer(),
            probeGateway: { _ in await probeCounter.increment(); return GatewayProbe.Result(reachable: true, latencyMs: 10) },
            probeExternal: { await probeCounter.increment(); return .ok },
            hasActiveInterface: { true },
            settings: makeSettings(),
            checkPermission: { _ in .needed },
            gatewayHost: { "127.0.0.1" },
            notificationCenter: NotificationCenter(),
            probeInterval: 0.05
        )

        store.start()
        await waitBriefly(0.3)
        store.stop()

        #expect(store.state.healthState == .permissionNeeded)
        #expect(await probeCounter.count == 0)
    }

    @Test func dispatchesProbeCycleResultsIntoState() async {
        let store = ConnectionHealthStore(
            reducer: ConnectionHealthReducer(),
            probeGateway: { _ in GatewayProbe.Result(reachable: true, latencyMs: 10) },
            probeExternal: { .ok },
            hasActiveInterface: { true },
            settings: makeSettings(),
            checkPermission: { _ in .granted },
            gatewayHost: { "127.0.0.1" },
            notificationCenter: NotificationCenter(),
            probeInterval: 0.05
        )

        store.start()
        await waitBriefly(0.3)
        store.stop()

        #expect(store.state.gatewayResult == .ok)
        #expect(store.state.externalResult == .ok)
    }

    @Test func noActiveInterfaceDispatchesNoNetworkState() async {
        let store = ConnectionHealthStore(
            reducer: ConnectionHealthReducer(),
            probeGateway: { _ in GatewayProbe.Result(reachable: true, latencyMs: 10) },
            probeExternal: { .ok },
            hasActiveInterface: { false },
            settings: makeSettings(),
            checkPermission: { _ in .granted },
            gatewayHost: { "127.0.0.1" },
            notificationCenter: NotificationCenter(),
            probeInterval: 0.05
        )

        store.start()
        await waitBriefly(0.3)
        store.stop()

        #expect(store.state.healthState == .noNetwork)
    }

    @Test func intervalChangeAtOrAboveMinimumPersistsAndReschedules() async {
        let settings = makeSettings()
        let store = ConnectionHealthStore(
            reducer: ConnectionHealthReducer(),
            probeGateway: { _ in GatewayProbe.Result(reachable: true, latencyMs: 10) },
            probeExternal: { .ok },
            hasActiveInterface: { true },
            settings: settings,
            checkPermission: { _ in .granted },
            gatewayHost: { "127.0.0.1" },
            notificationCenter: NotificationCenter(),
            probeInterval: 0.05
        )

        store.start()
        await waitBriefly(0.1)
        store.send(.intervalChanged(2))
        await waitBriefly(0.1)
        store.stop()

        #expect(store.state.probeInterval == 2)
        #expect(store.state.errorMessage == nil)
        #expect(settings.probeInterval == 2)
    }

    @Test func intervalChangeBelowMinimumIsRejectedWithAnErrorMessage() async {
        let settings = makeSettings()
        let store = ConnectionHealthStore(
            reducer: ConnectionHealthReducer(),
            probeGateway: { _ in GatewayProbe.Result(reachable: true, latencyMs: 10) },
            probeExternal: { .ok },
            hasActiveInterface: { true },
            settings: settings,
            checkPermission: { _ in .granted },
            gatewayHost: { "127.0.0.1" },
            notificationCenter: NotificationCenter(),
            probeInterval: 0.05
        )

        store.start()
        await waitBriefly(0.1)
        let intervalBefore = store.state.probeInterval
        store.send(.intervalChanged(0.02))
        await waitBriefly(0.1)
        store.stop()

        #expect(store.state.probeInterval == intervalBefore)
        #expect(store.state.errorMessage != nil)
    }

    @Test func pausesProbingOnSleepAndResumesOnWake() async {
        actor Counter { var count = 0; func increment() { count += 1 } }
        let counter = Counter()
        let center = NotificationCenter()

        let store = ConnectionHealthStore(
            reducer: ConnectionHealthReducer(),
            probeGateway: { _ in await counter.increment(); return GatewayProbe.Result(reachable: true, latencyMs: 10) },
            probeExternal: { .ok },
            hasActiveInterface: { true },
            settings: makeSettings(),
            checkPermission: { _ in .granted },
            gatewayHost: { "127.0.0.1" },
            notificationCenter: center,
            probeInterval: 0.05
        )

        store.start()
        await waitBriefly(0.15)
        center.post(name: NSWorkspace.willSleepNotification, object: nil)
        await waitBriefly(0.05)
        let countAtSleep = await counter.count

        await waitBriefly(0.3)
        let countWhileAsleep = await counter.count
        #expect(countWhileAsleep == countAtSleep)

        center.post(name: NSWorkspace.didWakeNotification, object: nil)
        await waitBriefly(0.3)
        store.stop()

        let countAfterWake = await counter.count
        #expect(countAfterWake > countWhileAsleep)
    }
}
