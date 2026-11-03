import SwiftUI

struct AddLinkBar: View {
    @Binding var text: String
    let error: LinkWatcherDomain.InputError?
    let canSubmit: Bool
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)

                TextField("Add a site to watch — example.com", text: $text)
                    .textFieldStyle(.plain)
                    .onSubmit(onSubmit)

                Button(action: onSubmit) {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .disabled(!canSubmit)
                .help("Start watching")
            }
            .padding(.leading, 16)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: .capsule)

            if let error {
                Text(error.message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.leading, 16)
                    .transition(.opacity)
            }
        }
        .animation(.smooth, value: error)
    }
}
