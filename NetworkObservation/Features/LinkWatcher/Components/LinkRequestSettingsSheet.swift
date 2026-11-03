import SwiftUI

/// Per-link request settings: which HTTP method is sent and which status codes count as online.
struct LinkRequestSettingsSheet: View {
    let link: MonitoredLink
    let onSave: (RequestSettings) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var method: HTTPMethod
    @State private var statusCodesText: String

    init(link: MonitoredLink, onSave: @escaping (RequestSettings) -> Void) {
        self.link = link
        self.onSave = onSave
        _method = State(initialValue: link.request.method)
        _statusCodesText = State(initialValue: link.request.acceptedStatusCodesText)
    }

    private var parsedStatusCodes: [Int]? {
        RequestSettings.parseStatusCodes(statusCodesText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                Section {
                    Picker("Method", selection: $method) {
                        ForEach(HTTPMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Accepted status codes", text: $statusCodesText, prompt: Text("200"))
                            .onSubmit(save)
                        if parsedStatusCodes == nil {
                            Text("Enter status codes from 100 to 599, separated by commas.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text(link.url.displayString)
                } footer: {
                    Text("Any other response counts as down. For a protected API checked without a token, add 401. POST, PUT and PATCH are sent without a body.")
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(parsedStatusCodes == nil)
            }
            .padding([.horizontal, .bottom], 20)
        }
        .frame(width: 440)
    }

    private func save() {
        guard let codes = parsedStatusCodes else { return }
        onSave(RequestSettings(method: method, acceptedStatusCodes: codes))
        dismiss()
    }
}
