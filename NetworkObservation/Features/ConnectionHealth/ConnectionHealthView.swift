//
//  ConnectionHealthView.swift
//  NetworkObservation
//
//  Status-bar icon (AC-01/AC-06/AC-07) + click-through breakdown popover (AC-02) +
//  probe-interval settings (AC-05).
//

import AppKit
import SwiftUI

extension ConnectionHealthDomain.HealthState {
    /// AC-01/AC-06/AC-08: good/degraded/unreachable are distinct; AC-03 keeps permission-needed
    /// on the unreachable color (distinguished by menu text, not color); AC-07 keeps no-network
    /// a fourth, distinct color.
    var statusBarColor: Color {
        switch self {
        case .good: return .green
        case .degraded: return .yellow
        case .unreachable, .permissionNeeded: return .red
        case .noNetwork: return .gray
        }
    }

    var statusBarSymbolName: String {
        switch self {
        case .good: return "network"
        case .degraded: return "network"
        case .unreachable: return "xmark.circle.fill"
        case .permissionNeeded: return "lock.circle.fill"
        case .noNetwork: return "network.slash"
        }
    }

    /// AC-03/AC-03b/AC-07: menu text that disambiguates states sharing a color, or a plain
    /// no-network cause, from a genuine unreachable reading.
    var menuExplanation: String {
        switch self {
        case .good: return "Connection is healthy."
        case .degraded: return "Connection is degraded."
        case .unreachable: return "Connection is unreachable."
        case .permissionNeeded: return "Local Network permission is required. Grant it in System Settings > Privacy & Security > Local Network."
        case .noNetwork: return "No active network interface (Wi-Fi/Ethernet)."
        }
    }
}

struct ConnectionHealthView: View {
    @Bindable var store: ConnectionHealthStore
    @State private var intervalText: String = ""
    /// Chart/stats redraw at 1Hz regardless of probeInterval, decoupling the sparkline's
    /// Canvas redraw cost from a probe cadence that can run as fast as 0.1s.
    @State private var displayLatencyHistory: [Double?] = []

    /// 8pt grid: 8 between rows within a section, 16 (2×8) between sections and as the
    /// popover's outer margin.
    private enum Spacing {
        static let row: CGFloat = 8
        static let section: CGFloat = 16
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.section) {
            Label {
                Text(store.state.healthState.menuExplanation)
            } icon: {
                Image(systemName: store.state.healthState.statusBarSymbolName)
                    .foregroundStyle(store.state.healthState.statusBarColor)
            }

            // Real-time gateway-latency strip chart (last ~60 probes).
            LatencySparklineView(samples: displayLatencyHistory)
            latencyStatsRow(samples: displayLatencyHistory)

            Divider()

            // AC-02: gateway and external breakdown shown separately on click.
            VStack(alignment: .leading, spacing: Spacing.row) {
                breakdownRow(label: "Gateway", result: store.state.gatewayResult)
                breakdownRow(label: "External", result: store.state.externalResult)
            }

            Divider()

            // AC-05: probe interval settings with inline validation.
            VStack(alignment: .leading, spacing: Spacing.row) {
                HStack {
                    Text("Probe interval (s)")
                    Spacer()
                    TextField("", text: $intervalText)
                        .frame(width: 48)
                        .multilineTextAlignment(.trailing)
                        .onSubmit {
                            if let value = TimeInterval(intervalText) {
                                store.send(.intervalChanged(value))
                            }
                        }
                }
                if let errorMessage = store.state.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(Spacing.section)
        .frame(minWidth: 240)
        .task { intervalText = String(store.state.probeInterval) }
        .task {
            while !Task.isCancelled {
                displayLatencyHistory = store.state.latencyHistory
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    @ViewBuilder
    private func latencyStatsRow(samples: [Double?]) -> some View {
        let values = samples.compactMap { $0 }
        HStack {
            latencyStat(label: "Min", value: values.min())
            Spacer()
            latencyStat(label: "Avg", value: values.isEmpty ? nil : values.reduce(0, +) / Double(values.count))
            Spacer()
            latencyStat(label: "Max", value: values.max())
        }
        .font(.caption)
    }

    @ViewBuilder
    private func latencyStat(label: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value.map { String(format: "%.0f ms", $0) } ?? "—")
        }
    }

    @ViewBuilder
    private func breakdownRow(label: String, result: ConnectionHealthDomain.ProbeResult?) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(result.map(String.init(describing:)) ?? "—")
                .foregroundStyle(.secondary)
        }
    }
}
