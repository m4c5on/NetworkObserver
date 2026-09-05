//
//  ConnectionHealthStore.swift
//  NetworkObservation
//
//  Owns the structured-concurrency probe loop (ADR-0002): checks Local Network permission
//  once, then runs a probe cycle per interval, dispatching each result through the Reducer;
//  pauses/resumes across system sleep/wake (spec §6 idle-overhead measurement).
//

import Foundation
import AppKit

@MainActor
@Observable
final class ConnectionHealthStore {

    private(set) var state: ConnectionHealthDomain.State

    private let reducer: ConnectionHealthReducer
    private let probeGateway: (String) async -> GatewayProbe.Result
    private let probeExternal: () async -> ConnectionHealthDomain.ProbeResult
    private let hasActiveInterface: () -> Bool
    private let settings: ConnectionHealthSettings
    private let checkPermission: (TimeInterval) async -> LocalNetworkPermission.Result
    private let gatewayHost: () -> String?
    private let notificationCenter: NotificationCenter
    private let logCycleCompleted: (Double) -> Void
    private let logHealthStateTransition: (ConnectionHealthDomain.HealthState, ConnectionHealthDomain.HealthState) -> Void

    private var loopTask: Task<Void, Never>?
    private var isPaused = false
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    init(
        reducer: ConnectionHealthReducer = ConnectionHealthReducer(),
        probeGateway: @escaping (String) async -> GatewayProbe.Result = { host in await GatewayProbe().probe(host: host) },
        probeExternal: @escaping () async -> ConnectionHealthDomain.ProbeResult = { await ExternalHostProbe().probe() },
        hasActiveInterface: @escaping () -> Bool = { NetworkInterfaceMonitor().hasActiveInterface() },
        settings: ConnectionHealthSettings = ConnectionHealthSettings(),
        checkPermission: @escaping (TimeInterval) async -> LocalNetworkPermission.Result = LocalNetworkPermission.checkPermission,
        gatewayHost: @escaping () -> String? = DefaultGateway.ipv4Address,
        notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        probeInterval: TimeInterval? = nil,
        hysteresisThreshold: Int? = nil,
        gatewayDegradedThresholdMs: Double? = nil,
        elapsedDegradedThresholdMs: Double? = nil,
        gatewayDegradedBadlyThresholdMs: Double? = nil,
        elapsedDegradedBadlyThresholdMs: Double? = nil,
        goodColorHex: String? = nil,
        degradedColorHex: String? = nil,
        badColorHex: String? = nil,
        logCycleCompleted: @escaping (Double) -> Void = { ConnectionHealthLogging.logCycleCompleted(elapsedMs: $0) },
        logHealthStateTransition: @escaping (ConnectionHealthDomain.HealthState, ConnectionHealthDomain.HealthState) -> Void = ConnectionHealthLogging.logHealthStateTransition
    ) {
        self.reducer = reducer
        self.probeGateway = probeGateway
        self.probeExternal = probeExternal
        self.hasActiveInterface = hasActiveInterface
        self.settings = settings
        self.checkPermission = checkPermission
        self.gatewayHost = gatewayHost
        self.notificationCenter = notificationCenter
        self.logCycleCompleted = logCycleCompleted
        self.logHealthStateTransition = logHealthStateTransition

        var initial = ConnectionHealthDomain.State.initial
        initial = ConnectionHealthDomain.State(
            healthState: initial.healthState,
            gatewayResult: initial.gatewayResult,
            externalResult: initial.externalResult,
            probeInterval: probeInterval ?? settings.probeInterval,
            errorMessage: initial.errorMessage,
            pendingCandidate: initial.pendingCandidate,
            pendingCount: initial.pendingCount,
            latencyHistory: initial.latencyHistory,
            hysteresisThreshold: hysteresisThreshold ?? settings.hysteresisThreshold,
            hysteresisErrorMessage: initial.hysteresisErrorMessage,
            elapsedHistory: initial.elapsedHistory,
            gatewayDegradedThresholdMs: gatewayDegradedThresholdMs ?? settings.gatewayDegradedThresholdMs,
            gatewayDegradedThresholdErrorMessage: initial.gatewayDegradedThresholdErrorMessage,
            elapsedDegradedThresholdMs: elapsedDegradedThresholdMs ?? settings.elapsedDegradedThresholdMs,
            elapsedDegradedThresholdErrorMessage: initial.elapsedDegradedThresholdErrorMessage,
            gatewayDegradedBadlyThresholdMs: gatewayDegradedBadlyThresholdMs ?? settings.gatewayDegradedBadlyThresholdMs,
            gatewayDegradedBadlyThresholdErrorMessage: initial.gatewayDegradedBadlyThresholdErrorMessage,
            elapsedDegradedBadlyThresholdMs: elapsedDegradedBadlyThresholdMs ?? settings.elapsedDegradedBadlyThresholdMs,
            elapsedDegradedBadlyThresholdErrorMessage: initial.elapsedDegradedBadlyThresholdErrorMessage,
            goodColorHex: goodColorHex ?? settings.goodColorHex,
            degradedColorHex: degradedColorHex ?? settings.degradedColorHex,
            badColorHex: badColorHex ?? settings.badColorHex
        )
        self.state = initial
    }

    func start() {
        guard loopTask == nil else { return }
        registerForSleepWake()
        loopTask = Task { [weak self] in
            await self?.runPermissionCheckThenLoop()
        }
    }

    func stop() {
        loopTask?.cancel()
        loopTask = nil
        if let sleepObserver { notificationCenter.removeObserver(sleepObserver) }
        if let wakeObserver { notificationCenter.removeObserver(wakeObserver) }
        sleepObserver = nil
        wakeObserver = nil
    }

    func send(_ intent: ConnectionHealthDomain.Intent) {
        let previousHealthState = state.healthState
        let (newState, effect) = reducer.reduce(state: state, intent: intent)
        state = newState
        if newState.healthState != previousHealthState {
            logHealthStateTransition(previousHealthState, newState.healthState)
        }
        guard let effect else { return }
        Task { [weak self] in await self?.execute(effect) }
    }

    // MARK: - Private

    private func execute(_ effect: ConnectionHealthDomain.Effect) async {
        switch effect {
        case .persistInterval(let candidate):
            if settings.setProbeInterval(candidate) {
                send(._intervalAccepted(candidate))
            } else {
                send(._intervalRejected(minimum: ConnectionHealthSettings.minimumProbeInterval))
            }

        case .rescheduleProbeLoop:
            loopTask?.cancel()
            loopTask = Task { [weak self] in await self?.probeLoop() }

        case .persistHysteresisThreshold(let candidate):
            if settings.setHysteresisThreshold(candidate) {
                send(._hysteresisThresholdAccepted(candidate))
            } else {
                send(._hysteresisThresholdRejected(minimum: ConnectionHealthSettings.minimumHysteresisThreshold))
            }

        case .persistGatewayDegradedThreshold(let candidate):
            if settings.setGatewayDegradedThreshold(candidate) {
                send(._gatewayDegradedThresholdAccepted(candidate))
            } else {
                send(._gatewayDegradedThresholdRejected(minimum: ConnectionHealthSettings.minimumGatewayDegradedThresholdMs))
            }

        case .persistElapsedDegradedThreshold(let candidate):
            if settings.setElapsedDegradedThreshold(candidate) {
                send(._elapsedDegradedThresholdAccepted(candidate))
            } else {
                send(._elapsedDegradedThresholdRejected(minimum: ConnectionHealthSettings.minimumElapsedDegradedThresholdMs))
            }

        case .persistGatewayDegradedBadlyThreshold(let candidate):
            if settings.setGatewayDegradedBadlyThreshold(candidate) {
                send(._gatewayDegradedBadlyThresholdAccepted(candidate))
            } else {
                send(._gatewayDegradedBadlyThresholdRejected(minimum: ConnectionHealthSettings.minimumGatewayDegradedBadlyThresholdMs))
            }

        case .persistElapsedDegradedBadlyThreshold(let candidate):
            if settings.setElapsedDegradedBadlyThreshold(candidate) {
                send(._elapsedDegradedBadlyThresholdAccepted(candidate))
            } else {
                send(._elapsedDegradedBadlyThresholdRejected(minimum: ConnectionHealthSettings.minimumElapsedDegradedBadlyThresholdMs))
            }

        case .persistGoodColor(let hex):
            settings.setGoodColorHex(hex)

        case .persistDegradedColor(let hex):
            settings.setDegradedColorHex(hex)

        case .persistBadColor(let hex):
            settings.setBadColorHex(hex)
        }
    }

    private func runPermissionCheckThenLoop() async {
        let result = await checkPermission(5)
        guard result == .granted else {
            send(._permissionNeeded)
            return
        }
        await probeLoop()
    }

    private func probeLoop() async {
        while !Task.isCancelled {
            while isPaused, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
            }
            guard !Task.isCancelled else { return }

            await runOneCycle()

            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .seconds(state.probeInterval))
        }
    }

    private func runOneCycle() async {
        guard hasActiveInterface() else {
            send(._noNetwork)
            return
        }

        let cycleStart = DispatchTime.now()

        guard let host = gatewayHost() else {
            let external = await probeExternal()
            let elapsed = elapsedMs(since: cycleStart)
            send(._cycleCompleted(gatewayLatencyMs: nil, external: external, elapsedMs: elapsed))
            logCycleCompleted(elapsed)
            return
        }

        async let gatewayResult = probeGateway(host)
        async let externalResult = probeExternal()
        let gateway = await gatewayResult
        let external = await externalResult
        let elapsed = elapsedMs(since: cycleStart)
        send(._cycleCompleted(gatewayLatencyMs: gateway.reachable ? gateway.latencyMs : nil, external: external, elapsedMs: elapsed))
        logCycleCompleted(elapsed)
    }

    private func elapsedMs(since start: DispatchTime) -> Double {
        Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
    }

    private func registerForSleepWake() {
        sleepObserver = notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isPaused = true
        }
        wakeObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isPaused = false
        }
    }
}
