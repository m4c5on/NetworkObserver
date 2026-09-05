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
    @State private var hysteresisText: String = ""
    @State private var settingsExpanded = false
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

            // Real-time gateway-latency strip chart + latency stats, set apart as one block.
            VStack(alignment: .leading, spacing: Spacing.row) {
                LatencySparklineView(samples: displayLatencyHistory)
                latencyStatsRow(samples: displayLatencyHistory)
            }
            .padding(Spacing.row)
            .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            // AC-02: gateway/external breakdown, one line.
            breakdownRow(gateway: store.state.gatewayResult, external: store.state.externalResult)

            Divider()

            HStack {
                Button("Settings") {
                    withAnimation { settingsExpanded.toggle() }
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }

            // AC-05/AC-04b: rarely-changed settings, slide out below the buttons on demand.
            if settingsExpanded {
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

                    HStack {
                        Text("Hysteresis (cycles)")
                        Spacer()
                        TextField("", text: $hysteresisText)
                            .frame(width: 48)
                            .multilineTextAlignment(.trailing)
                            .onSubmit {
                                if let value = Int(hysteresisText) {
                                    store.send(.hysteresisThresholdChanged(value))
                                }
                            }
                    }
                    if let hysteresisErrorMessage = store.state.hysteresisErrorMessage {
                        Text(hysteresisErrorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(Spacing.section)
        .frame(minWidth: 200)
        .task { intervalText = String(store.state.probeInterval) }
        .task { hysteresisText = String(store.state.hysteresisThreshold) }
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
        let format: (Double) -> String = { String(format: "%.0f ms", $0) }
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
    private func breakdownRow(gateway: ConnectionHealthDomain.ProbeResult?, external: ConnectionHealthDomain.ProbeResult?) -> some View {
        HStack {
            Text("Gateway")
            probeResultIcon(gateway)
            Spacer()
            Text("External")
            probeResultIcon(external)
        }
    }

    @ViewBuilder
    private func probeResultIcon(_ result: ConnectionHealthDomain.ProbeResult?) -> some View {
        switch result {
        case .ok:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .slow:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
        case .failing:
            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
        case nil:
            Image(systemName: "questionmark.circle").foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func statColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
        }
    }
}
