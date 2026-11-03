import Foundation
import Testing
@testable import NetworkObservation

struct LinkWatcherReducerTests {
    private typealias Domain = LinkWatcherDomain

    private let reducer = LinkWatcherReducer()
    private let linkID = UUID()
    private let start = Date(timeIntervalSince1970: 1_000)
    private let firefox = Browser(appURL: URL(fileURLWithPath: "/Applications/Firefox.app"), name: "Firefox")

    // MARK: - Lifecycle

    @Test func preparesOnlyOnce() {
        let (loaded, firstEffect) = reducer.reduce(state: .initial, intent: .viewAppeared)
        let (_, secondEffect) = reducer.reduce(state: loaded, intent: .viewAppeared)

        #expect(firstEffect == .prepare)
        #expect(secondEffect == nil)
    }

    @Test func restoresSavedBrowserWhenStillInstalled() {
        let (state, _) = reducer.reduce(
            state: .initial,
            intent: ._loaded(browsers: [firefox], savedBrowserAppURL: firefox.appURL, checkInterval: nil)
        )

        #expect(state.selectedBrowser == firefox)
    }

    @Test func dropsSavedBrowserThatIsNoLongerInstalled() {
        let (state, _) = reducer.reduce(
            state: .initial,
            intent: ._loaded(browsers: [], savedBrowserAppURL: firefox.appURL, checkInterval: nil)
        )

        #expect(state.selectedBrowser == nil)
    }

    // MARK: - Adding

    @Test func addingValidURLClearsInputAndStartsMonitoring() throws {
        let state = Domain.State.initial.copy(inputText: "staging.example.com")

        let (newState, effect) = reducer.reduce(state: state, intent: .addTapped)

        let url = try #require(URL(string: "https://staging.example.com"))
        #expect(newState.inputText.isEmpty)
        #expect(effect == .startMonitoring(url: url))
    }

    @Test func addingInvalidURLShowsError() {
        let state = Domain.State.initial.copy(inputText: "not a url")

        let (newState, effect) = reducer.reduce(state: state, intent: .addTapped)

        #expect(newState.inputError == .invalidURL)
        #expect(effect == nil)
    }

    @Test func addingDuplicateURLShowsError() throws {
        let state = Domain.State.initial.copy(links: [try makeLink()], inputText: "staging.example.com")

        let (newState, effect) = reducer.reduce(state: state, intent: .addTapped)

        #expect(newState.inputError == .alreadyWatching)
        #expect(effect == nil)
    }

    // MARK: - Monitoring

    @Test func wentOfflineNotifiesWithReason() throws {
        let link = try makeLink(state: .online)
        let state = Domain.State.initial.copy(links: [link])
        let update = MonitorUpdate(result: .down(.httpStatus(502)), state: .offline, isVerifying: false, transition: .wentOffline)

        let (newState, effect) = reducer.reduce(
            state: state,
            intent: ._monitorUpdated(linkID: linkID, update: update, at: start.addingTimeInterval(30))
        )

        #expect(newState.link(linkID)?.state == .offline)
        #expect(effect == .notify(ConnectionAlert(linkID: linkID, url: link.url, kind: .wentOffline(.httpStatus(502)))))
    }

    @Test func cameOnlineNotifiesWithDowntime() throws {
        let link = try makeLink(state: .offline)
        let state = Domain.State.initial.copy(links: [link])
        let update = MonitorUpdate(
            result: .up(statusCode: 200, latency: .milliseconds(90)),
            state: .online,
            isVerifying: false,
            transition: .cameOnline
        )

        let (_, effect) = reducer.reduce(
            state: state,
            intent: ._monitorUpdated(linkID: linkID, update: update, at: start.addingTimeInterval(125))
        )

        #expect(effect == .notify(ConnectionAlert(linkID: linkID, url: link.url, kind: .cameOnline(downtime: 125))))
    }

    @Test func updateWithoutTransitionDoesNotNotify() throws {
        let state = Domain.State.initial.copy(links: [try makeLink(state: .online)])
        let update = MonitorUpdate(result: .down(.timeout), state: .online, isVerifying: true, transition: nil)

        let (newState, effect) = reducer.reduce(
            state: state,
            intent: ._monitorUpdated(linkID: linkID, update: update, at: start)
        )

        #expect(newState.link(linkID)?.isVerifying == true)
        #expect(effect == nil)
    }

    // MARK: - Actions

    @Test func selectingBrowserSavesIt() {
        let (state, effect) = reducer.reduce(state: .initial, intent: .browserSelected(firefox))

        #expect(state.selectedBrowser == firefox)
        #expect(effect == .saveBrowser(firefox))
    }

    @Test func openingUsesGlobalBrowser() throws {
        let link = try makeLink()
        let state = Domain.State.initial.copy(links: [link], selectedBrowser: .set(firefox))

        let (_, effect) = reducer.reduce(state: state, intent: .openTapped(linkID: linkID))

        #expect(effect == .open(url: link.url, browser: firefox))
    }

    @Test func tappingNotificationOpensOnlyOnlineLinks() throws {
        let offlineState = Domain.State.initial.copy(links: [try makeLink(state: .offline)])
        let onlineState = Domain.State.initial.copy(links: [try makeLink(state: .online)])

        let (_, offlineEffect) = reducer.reduce(state: offlineState, intent: .notificationTapped(linkID: linkID))
        let (_, onlineEffect) = reducer.reduce(state: onlineState, intent: .notificationTapped(linkID: linkID))

        #expect(offlineEffect == nil)
        #expect(onlineEffect != nil)
    }

    @Test func removingLinkStopsMonitoring() throws {
        let state = Domain.State.initial.copy(links: [try makeLink()])

        let (newState, effect) = reducer.reduce(state: state, intent: .removeTapped(linkID: linkID))

        #expect(newState.links.isEmpty)
        #expect(effect == .stopMonitoring(linkID: linkID))
    }

    @Test func resettingStatisticsKeepsConnectionState() throws {
        let link = try makeLink(state: .online)
            .applying(MonitorUpdate(result: .down(.timeout), state: .online, isVerifying: true, transition: nil), at: start)
        let state = Domain.State.initial.copy(links: [link])

        let (newState, _) = reducer.reduce(state: state, intent: .resetStatisticsTapped(linkID: linkID))

        let updated = try #require(newState.link(linkID))
        #expect(updated.statistics == .empty)
        #expect(updated.state == .online)
    }

    // MARK: - Pause & Mute

    @Test func pausingStopsMonitoringAndMarksLink() throws {
        let state = Domain.State.initial.copy(links: [try makeLink(state: .online)])

        let (newState, effect) = reducer.reduce(state: state, intent: .pauseToggled(linkID: linkID))

        #expect(newState.link(linkID)?.isPaused == true)
        #expect(effect == .stopMonitoring(linkID: linkID))
    }

    @Test func resumingRequestsMonitoringRestart() throws {
        let link = try makeLink(state: .online).paused()
        let state = Domain.State.initial.copy(links: [link])

        let (_, effect) = reducer.reduce(state: state, intent: .pauseToggled(linkID: linkID))

        #expect(effect == .resumeMonitoring(linkID: linkID, url: link.url, request: .default))
    }

    @Test func resumedLinkStartsFromUnknownState() throws {
        let resumeDate = start.addingTimeInterval(300)
        let state = Domain.State.initial.copy(links: [try makeLink(state: .offline).paused()])

        let (newState, _) = reducer.reduce(state: state, intent: ._monitoringResumed(linkID: linkID, at: resumeDate))

        let link = try #require(newState.link(linkID))
        #expect(!link.isPaused)
        #expect(link.state == .unknown)
        #expect(link.stateSince == resumeDate)
        #expect(link.consecutiveFailures == 0)
    }

    @Test func updatesForPausedLinkAreIgnored() throws {
        let state = Domain.State.initial.copy(links: [try makeLink(state: .online).paused()])
        let update = MonitorUpdate(result: .down(.timeout), state: .offline, isVerifying: false, transition: .wentOffline)

        let (newState, effect) = reducer.reduce(
            state: state,
            intent: ._monitorUpdated(linkID: linkID, update: update, at: start)
        )

        #expect(newState == state)
        #expect(effect == nil)
    }

    @Test func mutedLinkUpdatesStateButDoesNotNotify() throws {
        let link = try makeLink(state: .online).togglingMute()
        let state = Domain.State.initial.copy(links: [link])
        let update = MonitorUpdate(result: .down(.timeout), state: .offline, isVerifying: false, transition: .wentOffline)

        let (newState, effect) = reducer.reduce(
            state: state,
            intent: ._monitorUpdated(linkID: linkID, update: update, at: start)
        )

        #expect(newState.link(linkID)?.state == .offline)
        #expect(effect == nil)
    }

    @Test func togglingMuteSavesWatchlist() throws {
        let state = Domain.State.initial.copy(links: [try makeLink()])

        let (newState, effect) = reducer.reduce(state: state, intent: .muteToggled(linkID: linkID))

        #expect(newState.link(linkID)?.isMuted == true)
        #expect(effect == .saveWatchlist)
    }

    // MARK: - Reordering

    @Test(arguments: [
        (moving: 0, onto: 2, expected: [1, 2, 0]),
        (moving: 2, onto: 0, expected: [2, 0, 1]),
        (moving: 0, onto: 1, expected: [1, 0, 2]),
    ])
    func movingALinkTakesThePositionOfTheTarget(moving: Int, onto: Int, expected: [Int]) throws {
        let links = try (0..<3).map { try makeLink(id: UUID(), url: "https://site\($0).example.com") }
        let state = Domain.State.initial.copy(links: links)

        let (newState, effect) = reducer.reduce(
            state: state,
            intent: .linkMoved(linkID: links[moving].id, toPositionOf: links[onto].id)
        )

        #expect(newState.links.map(\.id) == expected.map { links[$0].id })
        #expect(effect == .saveWatchlist)
    }

    @Test func movingALinkOntoItselfChangesNothing() throws {
        let state = Domain.State.initial.copy(links: [try makeLink()])

        let (newState, effect) = reducer.reduce(state: state, intent: .linkMoved(linkID: linkID, toPositionOf: linkID))

        #expect(newState == state)
        #expect(effect == nil)
    }

    @Test func movingAnUnknownLinkChangesNothing() throws {
        let state = Domain.State.initial.copy(links: [try makeLink()])

        let (newState, effect) = reducer.reduce(state: state, intent: .linkMoved(linkID: UUID(), toPositionOf: linkID))

        #expect(newState == state)
        #expect(effect == nil)
    }

    // MARK: - Request settings

    @Test func changingRequestSettingsRestartsMonitoringWithThem() throws {
        let state = Domain.State.initial.copy(links: [try makeLink(state: .online)])
        let request = RequestSettings(method: .post, acceptedStatusCodes: [200, 401])

        let (newState, effect) = reducer.reduce(state: state, intent: .requestSettingsChanged(linkID: linkID, request))

        let link = try #require(newState.link(linkID))
        #expect(link.request == request)
        #expect(effect == .resumeMonitoring(linkID: linkID, url: link.url, request: request))
    }

    @Test func changingRequestSettingsOfAPausedLinkOnlySavesThem() throws {
        let state = Domain.State.initial.copy(links: [try makeLink().paused()])
        let request = RequestSettings(method: .head, acceptedStatusCodes: [200])

        let (newState, effect) = reducer.reduce(state: state, intent: .requestSettingsChanged(linkID: linkID, request))

        #expect(newState.link(linkID)?.request == request)
        #expect(newState.link(linkID)?.isPaused == true)
        #expect(effect == .saveWatchlist)
    }

    @Test func unchangedRequestSettingsDoNothing() throws {
        let state = Domain.State.initial.copy(links: [try makeLink(state: .online)])

        let (newState, effect) = reducer.reduce(state: state, intent: .requestSettingsChanged(linkID: linkID, .default))

        #expect(newState == state)
        #expect(effect == nil)
    }

    // MARK: - Check interval

    @Test func sitesAreCheckedEvery15SecondsByDefault() {
        #expect(Domain.State.initial.checkInterval == 15)
    }

    @Test func restoresTheSavedCheckInterval() {
        let (state, _) = reducer.reduce(
            state: .initial,
            intent: ._loaded(browsers: [], savedBrowserAppURL: nil, checkInterval: 60)
        )

        #expect(state.checkInterval == 60)
    }

    @Test func ignoresASavedCheckIntervalThatIsNoLongerOffered() {
        let (state, _) = reducer.reduce(
            state: .initial,
            intent: ._loaded(browsers: [], savedBrowserAppURL: nil, checkInterval: 7)
        )

        #expect(state.checkInterval == 15)
    }

    @Test func changingTheCheckIntervalAppliesIt() {
        let (state, effect) = reducer.reduce(state: .initial, intent: .checkIntervalChanged(30))

        #expect(state.checkInterval == 30)
        #expect(effect == .applyCheckInterval(30))
    }

    @Test(arguments: [15, 7, 0])
    func unchangedOrUnofferedCheckIntervalDoesNothing(_ seconds: Int) {
        let (state, effect) = reducer.reduce(state: .initial, intent: .checkIntervalChanged(seconds))

        #expect(state == .initial)
        #expect(effect == nil)
    }

    // MARK: - Network availability

    @Test func networkIsAssumedAvailableUntilToldOtherwise() {
        #expect(Domain.State.initial.isNetworkAvailable)
    }

    @Test func networkAvailabilityChangeIsShownWithoutSideEffects() {
        let (offline, offlineEffect) = reducer.reduce(state: .initial, intent: .networkAvailabilityChanged(false))
        let (online, onlineEffect) = reducer.reduce(state: offline, intent: .networkAvailabilityChanged(true))

        #expect(offline.isNetworkAvailable == false)
        #expect(offlineEffect == nil)
        #expect(online.isNetworkAvailable)
        #expect(onlineEffect == nil)
    }

    // MARK: - Helpers

    private func makeLink(
        id: UUID? = nil,
        url urlString: String = "https://staging.example.com",
        state: ConnectionState = .unknown
    ) throws -> MonitoredLink {
        let url = try #require(URL(string: urlString))
        let link = MonitoredLink.new(id: id ?? linkID, url: url, startedAt: start)
        guard state != .unknown else { return link }
        let result: CheckResult = state == .online ? .up(statusCode: 200, latency: .milliseconds(50)) : .down(.timeout)
        return link.applying(MonitorUpdate(result: result, state: state, isVerifying: false, transition: nil), at: start)
    }
}
