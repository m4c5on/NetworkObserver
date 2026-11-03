//
//  NetworkObservationApp.swift
//  NetworkObservation
//
//  Created by Maksym on 03/09/2026.
//

import SwiftUI

@main
struct NetworkObservationApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    private var coordinator: AppCoordinator { appDelegate.coordinator }

    var body: some Scene {
        Window("NetworkObserver", id: MainWindow.id) {
            MainWindowView(
                connectionHealthStore: coordinator.connectionHealthStore,
                linkWatcherStore: coordinator.linkWatcherStore
            )
        }
        .defaultSize(width: 920, height: 560)

        MenuBarExtra {
            ConnectionHealthView(store: coordinator.connectionHealthStore)
        } label: {
            StatusBarLabel(coordinator: coordinator)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(
                connectionHealthStore: coordinator.connectionHealthStore,
                linkWatcherStore: coordinator.linkWatcherStore
            )
        }
    }
}

private struct StatusBarLabel: View {
    let coordinator: AppCoordinator
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let state = coordinator.connectionHealthStore.state
        Image(nsImage: state.healthState.statusBarImage(
            good: state.goodColor,
            degraded: state.degradedColor,
            bad: state.badColor
        ))
        .task {
            coordinator.openMainWindow = { openWindow(id: MainWindow.id) }
        }
    }
}
