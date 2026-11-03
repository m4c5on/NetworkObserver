import Foundation
import Observation

@MainActor
@Observable
final class LinkWatcherStore {
    typealias Domain = LinkWatcherDomain

    // MARK: - Public

    private(set) var state: Domain.State

    // MARK: - Private

    private let reducer: LinkWatcherReducer
    private let monitorLink: any MonitorLinkUseCase
    private let browserService: any BrowserService
    private let notifier: any ConnectionNotifier
    private let repository: any WatchlistRepository
    private let now: () -> Date
    private let makeID: () -> UUID

    @ObservationIgnored private var monitorTasks: [UUID: Task<Void, Never>] = [:]

    // MARK: - Init

    init(
        initialState: Domain.State = .initial,
        reducer: LinkWatcherReducer = LinkWatcherReducer(),
        monitorLink: any MonitorLinkUseCase,
        browserService: any BrowserService,
        notifier: any ConnectionNotifier,
        repository: any WatchlistRepository,
        now: @escaping () -> Date = { Date() },
        makeID: @escaping () -> UUID = { UUID() }
    ) {
        self.state = initialState
        self.reducer = reducer
        self.monitorLink = monitorLink
        self.browserService = browserService
        self.notifier = notifier
        self.repository = repository
        self.now = now
        self.makeID = makeID
    }

    // MARK: - Public

    func send(_ intent: Domain.Intent) {
        let (newState, effect) = reducer.reduce(state: state, intent: intent)
        state = newState

        guard let effect else { return }
        Task { await execute(effect) }
    }

    // MARK: - Private

    private func execute(_ effect: Domain.Effect) async {
        switch effect {
        case .prepare:
            send(._loaded(
                browsers: browserService.installedBrowsers(),
                savedBrowserAppURL: repository.loadBrowserAppURL()
            ))
            for storedLink in repository.loadLinks() {
                addLink(storedLink)
            }
            await notifier.requestAuthorization()

        case .clearBadge:
            await notifier.clearBadge()

        case .startMonitoring(let url):
            addLink(StoredLink(url: url, isPaused: false, isMuted: false, request: .default))
            saveWatchlist()

        case .resumeMonitoring(let linkID, let url, let request):
            send(._monitoringResumed(linkID: linkID, at: now()))
            startMonitorTask(linkID: linkID, url: url, request: request)
            saveWatchlist()

        case .stopMonitoring(let linkID):
            monitorTasks.removeValue(forKey: linkID)?.cancel()
            saveWatchlist()

        case .saveWatchlist:
            saveWatchlist()

        case .notify(let alert):
            await notifier.notify(alert)

        case .open(let url, let browser):
            browserService.open(url, in: browser)

        case .saveBrowser(let browser):
            repository.saveBrowserAppURL(browser?.appURL)
        }
    }

    private func addLink(_ storedLink: StoredLink) {
        let link = MonitoredLink.new(
            id: makeID(),
            url: storedLink.url,
            startedAt: now(),
            isPaused: storedLink.isPaused,
            isMuted: storedLink.isMuted,
            request: storedLink.request
        )
        send(._linkAdded(link))

        guard !link.isPaused else { return }
        startMonitorTask(linkID: link.id, url: link.url, request: link.request)
    }

    private func startMonitorTask(linkID: UUID, url: URL, request: RequestSettings) {
        monitorTasks[linkID]?.cancel()

        let updates = monitorLink.execute(url: url, request: request)
        monitorTasks[linkID] = Task { [weak self] in
            for await update in updates {
                guard let self else { return }
                send(._monitorUpdated(linkID: linkID, update: update, at: now()))
            }
        }
    }

    private func saveWatchlist() {
        repository.saveLinks(state.links.map(\.stored))
    }
}
