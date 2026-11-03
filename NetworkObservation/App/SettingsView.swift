//
//  SettingsView.swift
//  NetworkObservation
//
//  The Settings window (⌘,): network health on one tab, site checks on the other.
//

import SwiftUI

struct SettingsView: View {
    let connectionHealthStore: ConnectionHealthStore
    let linkWatcherStore: LinkWatcherStore

    var body: some View {
        TabView {
            Tab("Network", systemImage: "network") {
                ConnectionHealthSettingsView(store: connectionHealthStore)
            }
            Tab("Sites", systemImage: "globe") {
                LinkWatcherSettingsView(store: linkWatcherStore)
            }
        }
    }
}
