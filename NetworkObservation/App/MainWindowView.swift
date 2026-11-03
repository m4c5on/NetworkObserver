//
//  MainWindowView.swift
//  NetworkObservation
//
//  The main window: network health on the left, the watched sites on the right.
//

import SwiftUI

enum MainWindow {
    static let id = "main"
}

struct MainWindowView: View {
    let connectionHealthStore: ConnectionHealthStore
    let linkWatcherStore: LinkWatcherStore

    var body: some View {
        NavigationSplitView {
            NetworkHealthPanel(store: connectionHealthStore)
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
        } detail: {
            LinkWatcherView(store: linkWatcherStore)
        }
    }
}
