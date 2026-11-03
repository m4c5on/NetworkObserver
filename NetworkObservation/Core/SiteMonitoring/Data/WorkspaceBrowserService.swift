import AppKit

@MainActor
final class WorkspaceBrowserService: BrowserService {
    private let workspace: NSWorkspace

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    func installedBrowsers() -> [Browser] {
        guard let probeURL = URL(string: "https://example.com") else { return [] }

        var seenNames = Set<String>()
        return workspace.urlsForApplications(toOpen: probeURL)
            .map { Browser(appURL: $0, name: displayName(for: $0)) }
            .filter { seenNames.insert($0.name).inserted }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func open(_ url: URL, in browser: Browser?) {
        guard let browser else {
            workspace.open(url)
            return
        }

        workspace.open(
            [url],
            withApplicationAt: browser.appURL,
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: { @Sendable _, error in
                guard error != nil else { return }
                Task { @MainActor in NSWorkspace.shared.open(url) }
            }
        )
    }

    private func displayName(for appURL: URL) -> String {
        let name = FileManager.default.displayName(atPath: appURL.path(percentEncoded: false))
        return name.hasSuffix(".app") ? String(name.dropLast(4)) : name
    }
}
