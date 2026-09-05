//
//  NetworkObservationApp.swift
//  NetworkObservation
//
//  Created by Maksym on 03/09/2026.
//

import SwiftUI
import SwiftData

@main
struct NetworkObservationApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var connectionHealthStore = ConnectionHealthStore()

    var body: some Scene {
        MenuBarExtra {
            ConnectionHealthView(store: connectionHealthStore)
                .task { connectionHealthStore.start() }
        } label: {
            Image(systemName: connectionHealthStore.state.healthState.statusBarSymbolName)
                .foregroundStyle(connectionHealthStore.state.healthState.statusBarColor)
        }
        .menuBarExtraStyle(.window)

        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
