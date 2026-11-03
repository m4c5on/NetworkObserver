//
//  SettingsView.swift
//  NetworkObservation
//
//  The Settings window (⌘,): general, network health, site checks and notifications tabs.
//

import SwiftUI

struct SettingsView: View {
    let connectionHealthStore: ConnectionHealthStore
    let linkWatcherStore: LinkWatcherStore
    let notificationPreferences: NotificationPreferences

    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") {
                GeneralSettingsView()
            }
            Tab("Network", systemImage: "network") {
                ConnectionHealthSettingsView(store: connectionHealthStore)
            }
            Tab("Sites", systemImage: "globe") {
                LinkWatcherSettingsView(store: linkWatcherStore)
            }
            Tab("Notifications", systemImage: "bell") {
                NotificationSettingsView(preferences: notificationPreferences)
            }
        }
    }
}
