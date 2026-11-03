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
            Section {
                Picker("Check every", selection: Binding(
                    get: { store.state.checkInterval },
                    set: { store.send(.checkIntervalChanged($0)) }
                )) {
                    ForEach(LinkWatcherDomain.checkIntervalOptions, id: \.self) { seconds in
                        Text(verbatim: Duration.seconds(seconds).formatted(.units(allowed: [.minutes, .seconds], width: .wide)))
                            .tag(seconds)
                    }
                }
            } footer: {
                Text("How often each site is checked. A failed check is repeated after 3 seconds before the site counts as down.")
                    .foregroundStyle(.secondary)
            }

            Section {
                BrowserPicker(
                    browsers: store.state.browsers,
                    selection: store.state.selectedBrowser,
                    onSelect: { store.send(.browserSelected($0)) }
                )
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }
}
