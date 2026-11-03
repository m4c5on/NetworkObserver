//
//  ConnectionHealthChartsView.swift
//  NetworkObservation
//
//  The Internet (cycle-time) and Router (gateway-latency) strip charts with their Min/Avg/Max
//  stats — shown in the status-bar popover and, taller, in the main window's network panel.
//

import SwiftUI

struct ConnectionHealthChartsView: View {
    let store: ConnectionHealthStore
    var chartHeight: CGFloat = 44

    /// Chart/stats redraw at 1Hz regardless of probeInterval, decoupling the sparkline's
    /// Canvas redraw cost from a probe cadence that can run as fast as 0.1s.
    @State private var displayLatencyHistory: [Double?] = []
    @State private var displayElapsedHistory: [Double] = []

    private enum Spacing {
        static let row: CGFloat = 8
        static let section: CGFloat = 16
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.section) {
            VStack(alignment: .leading, spacing: Spacing.row) {
                HStack(spacing: 4) {
                    Text("Internet").font(.caption).foregroundStyle(.secondary)
                    probeResultIcon(store.state.externalResult)
                }
                LatencySparklineView(samples: displayElapsedHistory.map { Optional($0) }, threshold: store.state.elapsedDegradedThresholdMs, badlyThreshold: store.state.elapsedDegradedBadlyThresholdMs, goodColor: store.state.goodColor, degradedColor: store.state.degradedColor, badColor: store.state.badColor, height: chartHeight)
                latencyStatsRow(samples: displayElapsedHistory.map { Optional($0) })
            }
            VStack(alignment: .leading, spacing: Spacing.row) {
                HStack(spacing: 4) {
                    Text("Router").font(.caption).foregroundStyle(.secondary)
                    probeResultIcon(store.state.gatewayResult)
                }
                LatencySparklineView(samples: displayLatencyHistory, threshold: store.state.gatewayDegradedThresholdMs, badlyThreshold: store.state.gatewayDegradedBadlyThresholdMs, goodColor: store.state.goodColor, degradedColor: store.state.degradedColor, badColor: store.state.badColor, height: chartHeight)
                latencyStatsRow(samples: displayLatencyHistory)
            }
        }
        .task {
            while !Task.isCancelled {
                displayLatencyHistory = store.state.latencyHistory
                displayElapsedHistory = store.state.elapsedHistory
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    @ViewBuilder
    private func latencyStatsRow(samples: [Double?]) -> some View {
        let values = samples.compactMap { $0 }
        let format: (Double) -> String = { String(localized: "\(Int($0.rounded())) ms") }
        HStack {
            statColumn(label: "Min", value: values.min().map(format) ?? "—")
            Spacer()
            statColumn(label: "Avg", value: values.isEmpty ? "—" : format(values.reduce(0, +) / Double(values.count)))
            Spacer()
            statColumn(label: "Max", value: values.max().map(format) ?? "—")
        }
        .font(.caption)
    }

    @ViewBuilder
    private func probeResultIcon(_ result: ConnectionHealthDomain.ProbeResult?) -> some View {
        switch result {
        case .ok:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(store.state.goodColor)
        case .slow:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(store.state.degradedColor)
        case .failing:
            Image(systemName: "xmark.circle.fill").foregroundStyle(store.state.badColor)
        case nil:
            Image(systemName: "questionmark.circle").foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func statColumn(label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
        }
    }
}
