//
//  AppCoordinator.swift
//  NetworkObservation
//
//  Owns the two monitors — connection health (status bar) and site checks (main window) —
//  and wires them together: when this Mac loses the internet, the site list shows its checks as
//  paused and an "internet lost/restored" notification is posted.
//

import Foundation
import Observation

protocol NetworkNotifier {
    func notifyNetwork(_ event: NetworkOutageEvent) async
}

final class AppCoordinator {
    let connectionHealthStore: ConnectionHealthStore
    let linkWatcherStore: LinkWatcherStore
    /// Set by the status-bar label — the one SwiftUI view alive for the whole run — so the Dock
    /// icon can reopen the main window after it was closed.
    var openMainWindow: (() -> Void)?

    private let networkNotifier: any NetworkNotifier
    private let now: () -> Date
    private var outageTracker = NetworkOutageTracker()
    private var observationTask: Task<Void, Never>?

    init(
        connectionHealthStore: ConnectionHealthStore,
        linkWatcherStore: LinkWatcherStore,
        networkNotifier: any NetworkNotifier,
        now: @escaping () -> Date = { Date() }
    ) {
        self.connectionHealthStore = connectionHealthStore
        self.linkWatcherStore = linkWatcherStore
        self.networkNotifier = networkNotifier
        self.now = now
    }

    static func live() -> AppCoordinator {
        let notifier = UserNotificationService()
        let linkWatcherStore = LinkWatcherStore(
            monitorLink: DefaultMonitorLinkUseCase(
                checker: URLSessionReachabilityChecker(),
                internetReachable: { @MainActor in await ExternalHostProbe().probe() != .failing }
            ),
            browserService: WorkspaceBrowserService(),
            notifier: notifier,
            repository: UserDefaultsWatchlistRepository()
        )
        notifier.onNotificationTapped = { [weak linkWatcherStore] linkID in
            linkWatcherStore?.send(.notificationTapped(linkID: linkID))
        }
        return AppCoordinator(
            connectionHealthStore: ConnectionHealthStore(),
            linkWatcherStore: linkWatcherStore,
            networkNotifier: notifier
        )
    }

    /// Both monitors run from launch, whether or not the main window is open.
    func start() {
        guard observationTask == nil else { return }
        connectionHealthStore.start()
        linkWatcherStore.send(.viewAppeared)

        let store = connectionHealthStore
        let readings = Observations { @MainActor in
            (store.state.healthState, store.state.externalResult)
        }
        observationTask = Task { [weak self] in
            for await (healthState, externalResult) in readings {
                self?.connectionHealthChanged(healthState: healthState, externalResult: externalResult)
            }
        }
    }

    func appBecameActive() {
        linkWatcherStore.send(.appBecameActive)
    }

    func connectionHealthChanged(
        healthState: ConnectionHealthDomain.HealthState,
        externalResult: ConnectionHealthDomain.ProbeResult?
    ) {
        guard let event = outageTracker.register(healthState: healthState, externalResult: externalResult, at: now()) else { return }
        linkWatcherStore.send(.networkAvailabilityChanged(event.isNetworkAvailable))
        let notifier = networkNotifier
        Task { await notifier.notifyNetwork(event) }
    }
}
