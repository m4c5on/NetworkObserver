//
//  LinkWatcherSettingsView.swift
//  NetworkObservation
//
//  The Sites tab of the Settings window.
//

import SwiftUI

struct LinkWatcherSettingsView: View {
    let store: LinkWatcherStore

    var body: some View {
        Form {
            BrowserPicker(
                browsers: store.state.browsers,
                selection: store.state.selectedBrowser,
                onSelect: { store.send(.browserSelected($0)) }
            )
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }
}
