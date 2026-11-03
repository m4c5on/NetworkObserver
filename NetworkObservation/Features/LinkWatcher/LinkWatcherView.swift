import SwiftUI

struct LinkWatcherView: View {
    @State var store: LinkWatcherStore
    @State private var linkBeingEdited: MonitoredLink?

    var body: some View {
        ZStack {
            Backdrop()
            content
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 8) {
                AddLinkBar(
                    text: Binding(
                        get: { store.state.inputText },
                        set: { store.send(.inputChanged($0)) }
                    ),
                    error: store.state.inputError,
                    canSubmit: store.state.canAdd,
                    onSubmit: { store.send(.addTapped) }
                )
                if !store.state.isNetworkAvailable {
                    NoInternetBanner()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(minWidth: 540, minHeight: 420)
        .navigationTitle("Sites")
        .navigationSubtitle(LinkWatcherFormatting.summary(for: store.state.links))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                }
                .help("Settings")
            }
        }
        .task { store.send(.viewAppeared) }
        .sheet(item: $linkBeingEdited) { link in
            LinkRequestSettingsSheet(link: link) { request in
                store.send(.requestSettingsChanged(linkID: link.id, request))
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.state.links.isEmpty {
            ContentUnavailableView(
                "No sites yet",
                systemImage: "waveform.path.ecg",
                description: Text("Add a website or API URL — you'll be notified when it goes down or comes back up.")
            )
        } else {
            ScrollView {
                GlassEffectContainer(spacing: 12) {
                    LazyVStack(spacing: 12) {
                        ForEach(store.state.links) { link in
                            LinkCard(
                                link: link,
                                onOpen: { store.send(.openTapped(linkID: link.id)) },
                                onTogglePause: { store.send(.pauseToggled(linkID: link.id)) },
                                onToggleMute: { store.send(.muteToggled(linkID: link.id)) },
                                onResetStatistics: { store.send(.resetStatisticsTapped(linkID: link.id)) },
                                onEditRequest: { linkBeingEdited = link },
                                onRemove: { store.send(.removeTapped(linkID: link.id)) }
                            )
                            // Drag a card onto another to reorder; the URL is the payload, so a
                            // card can also be dropped into a browser.
                            .draggable(link.url)
                            .dropDestination(for: URL.self) { urls, _ in
                                guard let url = urls.first,
                                      let moved = store.state.links.first(where: { $0.url == url })
                                else { return false }
                                store.send(.linkMoved(linkID: moved.id, toPositionOf: link.id))
                                return true
                            }
                        }
                    }
                    .animation(.smooth, value: store.state.links.map(\.id))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
        }
    }
}

/// Failed checks are ignored while this Mac is offline, so a site is never reported down
/// because of our own connection.
private struct NoInternetBanner: View {
    var body: some View {
        Label("No internet connection — site checks are paused", systemImage: "wifi.slash")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(.orange.opacity(0.2)), in: .capsule)
    }
}

private struct Backdrop: View {
    var body: some View {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.20), Color.purple.opacity(0.08), Color.clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
