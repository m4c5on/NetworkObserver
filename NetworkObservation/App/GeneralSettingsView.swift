//
//  GeneralSettingsView.swift
//  NetworkObservation
//
//  The General tab of the Settings window: the interface language.
//

import AppKit
import SwiftUI

struct GeneralSettingsView: View {
    /// The language the app is running in; a different choice needs a restart to take effect.
    private static let languageAtLaunch = AppLanguageSettings().current

    @State private var language = AppLanguageSettings().current

    var body: some View {
        Form {
            Section {
                Picker("Language", selection: $language) {
                    ForEach(AppLanguage.allCases) { language in
                        if let nativeName = language.nativeName {
                            Text(verbatim: nativeName).tag(language)
                        } else {
                            Text("System").tag(language)
                        }
                    }
                }
                .onChange(of: language) { _, newLanguage in
                    AppLanguageSettings().set(newLanguage)
                }
            } footer: {
                if language != Self.languageAtLaunch {
                    HStack {
                        Text("Restart the app to switch the language.")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Restart Now", action: relaunch)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }

    /// Starts a fresh copy of the app, then quits this one.
    private func relaunch() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, _ in
            Task { @MainActor in NSApplication.shared.terminate(nil) }
        }
    }
}
