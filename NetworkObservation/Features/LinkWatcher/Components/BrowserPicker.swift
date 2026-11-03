import AppKit
import SwiftUI

struct BrowserPicker: View {
    let browsers: [Browser]
    let selection: Browser?
    let onSelect: (Browser?) -> Void

    var body: some View {
        Picker(
            "Open links with",
            selection: Binding(get: { selection }, set: { onSelect($0) })
        ) {
            Label("System Default", systemImage: "globe")
                .tag(Browser?.none)

            ForEach(browsers) { browser in
                Label {
                    Text(browser.name)
                } icon: {
                    Image(nsImage: BrowserIcon.image(for: browser))
                }
                .tag(Optional(browser))
            }
        }
    }
}

nonisolated enum BrowserIcon {
    @MainActor
    static func image(for browser: Browser) -> NSImage {
        let image = NSWorkspace.shared.icon(forFile: browser.appURL.path(percentEncoded: false))
        image.size = NSSize(width: 16, height: 16)
        return image
    }
}
