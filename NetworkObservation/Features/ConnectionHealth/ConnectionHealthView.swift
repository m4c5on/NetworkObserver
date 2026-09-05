//
//  ConnectionHealthView.swift
//  NetworkObservation
//
//  Status-bar icon (AC-01/AC-06/AC-07) + click-through breakdown popover (AC-02) +
//  probe-interval settings (AC-05).
//

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
        case .good: return "checkmark.circle.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .unreachable: return "xmark.circle.fill"
        case .permissionNeeded: return "lock.circle.fill"
        case .noNetwork: return "wifi.slash"
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

    var body: some View {
        Label {
            Text(store.state.healthState.menuExplanation)
        } icon: {
            Image(systemName: store.state.healthState.statusBarSymbolName)
                .foregroundStyle(store.state.healthState.statusBarColor)
        }
        .task { intervalText = String(Int(store.state.probeInterval)) }

        Divider()

        // AC-02: gateway and external breakdown shown separately on click.
        VStack(alignment: .leading) {
            breakdownRow(label: "Gateway", result: store.state.gatewayResult)
            breakdownRow(label: "External", result: store.state.externalResult)
        }

        Divider()

        // AC-05: probe interval settings with inline validation.
        HStack {
            Text("Probe interval (s)")
            TextField("", text: $intervalText)
                .onSubmit {
                    if let value = TimeInterval(intervalText) {
                        store.send(.intervalChanged(value))
                    }
                }
        }
        if let errorMessage = store.state.errorMessage {
            Text(errorMessage).foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private func breakdownRow(label: String, result: ConnectionHealthDomain.ProbeResult?) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(result.map(String.init(describing:)) ?? "—")
        }
    }
}
