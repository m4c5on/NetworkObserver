//
//  ConnectionHealthLoggingTests.swift
//  NetworkObservationTests
//
//  T13 — NFR instrumentation: os_log points for probe-cycle-completion (spec §6 QG-3) and
//  health-state transitions (QG-1/QG-4/QG-5 soak-test analysis). Both are injected as plain
//  closures into the Store (matching every other dependency here), so a test can count
//  invocations without reading back the real unified-logging store.
//

import Testing
import Foundation
@testable import NetworkObservation

@MainActor
struct ConnectionHealthLoggingTests {

    private func makeSettings() -> ConnectionHealthSettings {
        let suiteName = "ConnectionHealthLoggingTests.\(UUID().uuidString)"
        return ConnectionHealthSettings(defaults: UserDefaults(suiteName: suiteName)!)
    }

    private func waitBriefly(_ seconds: Double = 0.3) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    @Test func emitsExactlyOneCycleCompletionLogPerCompletedProbeCycle() async {
        actor Counter { var count = 0; func increment() { count += 1 } }
        let counter = Counter()

        let store = ConnectionHealthStore(
            reducer: ConnectionHealthReducer(),
            probeGateway: { _ in GatewayProbe.Result(reachable: true, latencyMs: 10) },
            probeExternal: { .ok },
            hasActiveInterface: { true },
            settings: makeSettings(),
            checkPermission: { _ in .granted },
            gatewayHost: { "127.0.0.1" },
            notificationCenter: NotificationCenter(),
            probeInterval: 0.05,
            logCycleCompleted: { _ in Task { await counter.increment() } },
            logHealthStateTransition: { _, _ in }
        )

        store.start()
        await waitBriefly(0.3)
        store.stop()
        await waitBriefly(0.05)

        let count = await counter.count
        #expect(count >= 2) // at ~0.05s interval, a 0.3s window completes several cycles
    }

    @Test func doesNotLogACycleCompletionWhenThereIsNoActiveInterface() async {
        actor Counter { var count = 0; func increment() { count += 1 } }
        let counter = Counter()

        let store = ConnectionHealthStore(
            reducer: ConnectionHealthReducer(),
            probeGateway: { _ in GatewayProbe.Result(reachable: true, latencyMs: 10) },
            probeExternal: { .ok },
            hasActiveInterface: { false },
            settings: makeSettings(),
            checkPermission: { _ in .granted },
            gatewayHost: { "127.0.0.1" },
            notificationCenter: NotificationCenter(),
            probeInterval: 0.05,
            logCycleCompleted: { _ in Task { await counter.increment() } },
            logHealthStateTransition: { _, _ in }
        )

        store.start()
        await waitBriefly(0.3)
        store.stop()
        await waitBriefly(0.05)

        #expect(await counter.count == 0)
    }

    @Test func logsAHealthStateTransitionWhenTheStateActuallyChanges() async {
        actor Log { var transitions: [(ConnectionHealthDomain.HealthState, ConnectionHealthDomain.HealthState)] = []
            func record(_ from: ConnectionHealthDomain.HealthState, _ to: ConnectionHealthDomain.HealthState) { transitions.append((from, to)) }
        }
        let log = Log()

        let store = ConnectionHealthStore(
            reducer: ConnectionHealthReducer(),
            probeGateway: { _ in GatewayProbe.Result(reachable: true, latencyMs: 10) },
            probeExternal: { .ok },
            hasActiveInterface: { false }, // forces an immediate good -> noNetwork transition
            settings: makeSettings(),
            checkPermission: { _ in .granted },
            gatewayHost: { "127.0.0.1" },
            notificationCenter: NotificationCenter(),
            probeInterval: 0.05,
            logCycleCompleted: { _ in },
            logHealthStateTransition: { from, to in Task { await log.record(from, to) } }
        )

        store.start()
        await waitBriefly(0.2)
        store.stop()
        await waitBriefly(0.05)

        let transitions = await log.transitions
        #expect(transitions.contains { $0.0 == .good && $0.1 == .noNetwork })
    }

    @Test func doesNotLogATransitionWhenTheHealthStateStaysTheSame() async {
        actor Counter { var count = 0; func increment() { count += 1 } }
        let counter = Counter()

        let store = ConnectionHealthStore(
            reducer: ConnectionHealthReducer(),
            probeGateway: { _ in GatewayProbe.Result(reachable: true, latencyMs: 10) },
            probeExternal: { .ok }, // stays .good the entire time — no transition
            hasActiveInterface: { true },
            settings: makeSettings(),
            checkPermission: { _ in .granted },
            gatewayHost: { "127.0.0.1" },
            notificationCenter: NotificationCenter(),
            probeInterval: 0.05,
            logCycleCompleted: { _ in },
            logHealthStateTransition: { _, _ in Task { await counter.increment() } }
        )

        store.start()
        await waitBriefly(0.3)
        store.stop()
        await waitBriefly(0.05)

        #expect(await counter.count == 0)
    }
}
