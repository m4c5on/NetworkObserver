//
//  NotificationSettingsView.swift
//  NetworkObservation
//
//  The Notifications tab of the Settings window: one switch per kind of notification.
//

import SwiftUI

struct NotificationSettingsView: View {
    let preferences: NotificationPreferences

    var body: some View {
        Form {
            Section {
                ForEach(NotificationKind.allCases) { kind in
                    Toggle(kind.title, isOn: Binding(
                        get: { preferences.isEnabled(kind) },
                        set: { preferences.setEnabled($0, for: kind) }
                    ))
                }
            } footer: {
                Text("To silence a single site, use the bell on its card.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }
}
