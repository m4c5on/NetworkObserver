//
//  ConnectionHealthSettingsView.swift
//  NetworkObservation
//
//  AC-05/AC-04b: probe interval, hysteresis, degraded thresholds and health-tier colors —
//  shown in the app's Settings window (⌘,).
//

import SwiftUI

struct ConnectionHealthSettingsView: View {
    let store: ConnectionHealthStore
    @State private var intervalText: String = ""
    @State private var hysteresisText: String = ""
    @State private var gatewayThresholdText: String = ""
    @State private var elapsedThresholdText: String = ""
    @State private var gatewayBadlyThresholdText: String = ""
    @State private var elapsedBadlyThresholdText: String = ""

    var body: some View {
        Form {
            Section("Probing") {
                numberField("Probe interval (s)", text: $intervalText, error: store.state.errorMessage) {
                    TimeInterval(intervalText).map { .intervalChanged($0) }
                }
                numberField("Hysteresis (cycles)", text: $hysteresisText, error: store.state.hysteresisErrorMessage) {
                    Int(hysteresisText).map { .hysteresisThresholdChanged($0) }
                }
            }

            Section("Thresholds") {
                numberField("Router threshold (ms)", text: $gatewayThresholdText, error: store.state.gatewayDegradedThresholdErrorMessage) {
                    Double(gatewayThresholdText).map { .gatewayDegradedThresholdChanged($0) }
                }
                numberField("Internet threshold (ms)", text: $elapsedThresholdText, error: store.state.elapsedDegradedThresholdErrorMessage) {
                    Double(elapsedThresholdText).map { .elapsedDegradedThresholdChanged($0) }
                }
                numberField("Router badly threshold (ms)", text: $gatewayBadlyThresholdText, error: store.state.gatewayDegradedBadlyThresholdErrorMessage) {
                    Double(gatewayBadlyThresholdText).map { .gatewayDegradedBadlyThresholdChanged($0) }
                }
                numberField("Internet badly threshold (ms)", text: $elapsedBadlyThresholdText, error: store.state.elapsedDegradedBadlyThresholdErrorMessage) {
                    Double(elapsedBadlyThresholdText).map { .elapsedDegradedBadlyThresholdChanged($0) }
                }
            }

            Section("Colors") {
                colorPicker("Good color", color: store.state.goodColor) { .goodColorChanged($0) }
                colorPicker("Degraded color", color: store.state.degradedColor) { .degradedColorChanged($0) }
                colorPicker("Bad color", color: store.state.badColor) { .badColorChanged($0) }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .task {
            intervalText = String(store.state.probeInterval)
            hysteresisText = String(store.state.hysteresisThreshold)
            gatewayThresholdText = String(Int(store.state.gatewayDegradedThresholdMs))
            elapsedThresholdText = String(Int(store.state.elapsedDegradedThresholdMs))
            gatewayBadlyThresholdText = String(Int(store.state.gatewayDegradedBadlyThresholdMs))
            elapsedBadlyThresholdText = String(Int(store.state.elapsedDegradedBadlyThresholdMs))
        }
    }

    /// The value is applied on Return; an out-of-range value is rejected by the Reducer and its
    /// error message is shown under the field.
    @ViewBuilder
    private func numberField(
        _ title: LocalizedStringKey,
        text: Binding<String>,
        error: String?,
        intent: @escaping () -> ConnectionHealthDomain.Intent?
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                TextField("", text: text)
                    .frame(width: 64)
                    .multilineTextAlignment(.trailing)
                    .onSubmit {
                        if let intent = intent() { store.send(intent) }
                    }
            }
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func colorPicker(
        _ title: LocalizedStringKey,
        color: Color,
        intent: @escaping (String) -> ConnectionHealthDomain.Intent
    ) -> some View {
        ColorPicker(title, selection: Binding(
            get: { color },
            set: { newColor in
                if let hex = newColor.hexString {
                    store.send(intent(hex))
                }
            }
        ))
    }
}
