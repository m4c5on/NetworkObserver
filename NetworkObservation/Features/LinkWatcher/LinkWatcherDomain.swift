import Foundation

nonisolated enum LinkWatcherDomain {
    /// Seconds between checks of each site, as offered in Settings > Sites.
    static let checkIntervalOptions = [5, 10, 15, 30, 60, 120, 300]
    static let defaultCheckInterval = 15

    struct State: Equatable {
        let links: [MonitoredLink]
        let inputText: String
        let inputError: InputError?
        let browsers: [Browser]
        let selectedBrowser: Browser?
        let hasLoaded: Bool
        /// False while this Mac has no internet: failed checks are ignored then (see
        /// `DefaultMonitorLinkUseCase`), and the window says the checks are paused.
        let isNetworkAvailable: Bool
        /// Seconds between checks of each site; one of `checkIntervalOptions`.
        let checkInterval: Int
    }

    enum InputError: Equatable {
        case invalidURL
        case alreadyWatching
    }

    enum Intent {
        // View
        case viewAppeared
        case appBecameActive
        case inputChanged(String)
        case addTapped
        case browserSelected(Browser?)
        case openTapped(linkID: UUID)
        case pauseToggled(linkID: UUID)
        case muteToggled(linkID: UUID)
        case resetStatisticsTapped(linkID: UUID)
        case removeTapped(linkID: UUID)
        /// Drag and drop: the moved link takes the target's position in the list.
        case linkMoved(linkID: UUID, toPositionOf: UUID)
        case requestSettingsChanged(linkID: UUID, RequestSettings)
        case checkIntervalChanged(Int)

        // App
        case networkAvailabilityChanged(Bool)

        // Internal
        case _loaded(browsers: [Browser], savedBrowserAppURL: URL?, checkInterval: Int?)
        case _linkAdded(MonitoredLink)
        case _monitoringResumed(linkID: UUID, at: Date)
        case _monitorUpdated(linkID: UUID, update: MonitorUpdate, at: Date)

        // Delegate
        case notificationTapped(linkID: UUID)
    }

    enum Effect: Equatable {
        case prepare
        case clearBadge
        case startMonitoring(url: URL)
        case resumeMonitoring(linkID: UUID, url: URL, request: RequestSettings)
        case stopMonitoring(linkID: UUID)
        case saveWatchlist
        case notify(ConnectionAlert)
        case open(url: URL, browser: Browser?)
        case saveBrowser(Browser?)
        /// Saves the interval and restarts monitoring of every active link with it.
        case applyCheckInterval(Int)
    }
}

nonisolated extension LinkWatcherDomain.State {
    static var initial: Self {
        Self(links: [], inputText: "", inputError: nil, browsers: [], selectedBrowser: nil, hasLoaded: false, isNetworkAvailable: true, checkInterval: LinkWatcherDomain.defaultCheckInterval)
    }

    var canAdd: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func link(_ id: UUID) -> MonitoredLink? {
        links.first { $0.id == id }
    }

    func updatingLink(_ id: UUID, _ transform: (MonitoredLink) -> MonitoredLink) -> Self {
        copy(links: links.map { $0.id == id ? transform($0) : $0 })
    }

    func copy(
        links: [MonitoredLink]? = nil,
        inputText: String? = nil,
        inputError: Patch<LinkWatcherDomain.InputError> = .keep,
        browsers: [Browser]? = nil,
        selectedBrowser: Patch<Browser> = .keep,
        hasLoaded: Bool? = nil,
        isNetworkAvailable: Bool? = nil,
        checkInterval: Int? = nil
    ) -> Self {
        Self(
            links: links ?? self.links,
            inputText: inputText ?? self.inputText,
            inputError: inputError.resolved(current: self.inputError),
            browsers: browsers ?? self.browsers,
            selectedBrowser: selectedBrowser.resolved(current: self.selectedBrowser),
            hasLoaded: hasLoaded ?? self.hasLoaded,
            isNetworkAvailable: isNetworkAvailable ?? self.isNetworkAvailable,
            checkInterval: checkInterval ?? self.checkInterval
        )
    }
}
