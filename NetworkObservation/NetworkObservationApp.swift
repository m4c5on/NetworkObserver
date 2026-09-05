//
//  NetworkObservationApp.swift
//  NetworkObservation
//
//  Created by Maksym on 03/09/2026.
//

import SwiftUI

@main
struct NetworkObservationApp: App {
    @State private var connectionHealthStore = ConnectionHealthStore()

    var body: some Scene {
        MenuBarExtra {
            ConnectionHealthView(store: connectionHealthStore)
        } label: {
            Image(nsImage: connectionHealthStore.state.healthState.statusBarImage(
                good: connectionHealthStore.state.goodColor,
                degraded: connectionHealthStore.state.degradedColor,
                bad: connectionHealthStore.state.badColor
            ))
                .task { connectionHealthStore.start() }
        }
        .menuBarExtraStyle(.window)
    }
}
