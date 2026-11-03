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
        // The network panel is always visible: no sidebar toggle, and the column can't collapse.
        NavigationSplitView(columnVisibility: .constant(.all)) {
            NetworkHealthPanel(store: connectionHealthStore)
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
                .toolbar(removing: .sidebarToggle)
        } detail: {
            LinkWatcherView(store: linkWatcherStore)
        }
    }
}
