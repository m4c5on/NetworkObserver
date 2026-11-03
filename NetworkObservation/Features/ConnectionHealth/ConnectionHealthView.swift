//
//  ConnectionHealthView.swift
//  NetworkObservation
//
//  Status-bar popover (AC-02): the Internet/Router charts plus shortcuts to the main window,
//  Settings and Quit.
//

import AppKit
import SwiftUI

struct ConnectionHealthView: View {
    let store: ConnectionHealthStore
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    /// 8pt grid: 8 between rows within a section, 16 (2×8) between sections and as the
    /// popover's outer margin.
    private enum Spacing {
        static let row: CGFloat = 8
        static let section: CGFloat = 16
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.section) {
            ConnectionHealthChartsView(store: store)
                .padding(Spacing.row)
                .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            HStack {
                Button("Open Window") {
                    openWindow(id: MainWindow.id)
                    NSApplication.shared.activate()
                }
                Button("Settings") {
                    openSettings()
                    NSApplication.shared.activate()
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(Spacing.section)
        .frame(minWidth: 280)
    }
}
