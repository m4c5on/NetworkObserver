//
//  ConnectionHealthView.swift
//  NetworkObservation
//
//  Status-bar popover (AC-02): the Internet/Router charts. The main window, Settings and Quit
//  are reached through the Dock icon and the app menu.
//

import SwiftUI

struct ConnectionHealthView: View {
    let store: ConnectionHealthStore

    /// 8pt grid: 8 inside the chart block, 16 (2×8) as the popover's outer margin.
    private enum Spacing {
        static let row: CGFloat = 8
        static let section: CGFloat = 16
    }

    var body: some View {
        ConnectionHealthChartsView(store: store)
            .padding(Spacing.row)
            .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .padding(Spacing.section)
            .frame(minWidth: 200)
    }
}
