//
//  NetworkHealthPanel.swift
//  NetworkObservation
//
//  Left column of the main window: the current network health state and the same charts as
//  the status-bar popover, drawn taller.
//

import SwiftUI

struct NetworkHealthPanel: View {
    let store: ConnectionHealthStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statusHeader
                ConnectionHealthChartsView(store: store, chartHeight: 96)
            }
            .padding(16)
        }
    }

    private var statusHeader: some View {
        let healthState = store.state.healthState
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: healthState.statusBarSymbolName)
                .font(.title2)
                .foregroundStyle(healthState.statusBarColor(
                    good: store.state.goodColor,
                    degraded: store.state.degradedColor,
                    bad: store.state.badColor
                ))
            VStack(alignment: .leading, spacing: 2) {
                Text("Network").font(.headline)
                Text(healthState.menuExplanation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
