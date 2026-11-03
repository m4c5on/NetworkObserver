import Foundation

nonisolated struct LinkWatcherReducer {
    typealias Domain = LinkWatcherDomain

    func reduce(
        state: Domain.State,
        intent: Domain.Intent
    ) -> (Domain.State, Domain.Effect?) {
        switch intent {
        case .viewAppeared:
            guard !state.hasLoaded else { return (state, nil) }
            return (state.copy(hasLoaded: true), .prepare)

        case .appBecameActive:
            return (state, .clearBadge)

        case .inputChanged(let text):
            return (state.copy(inputText: text, inputError: .clear), nil)

        case .addTapped:
            return reduceAdd(state: state)

        case .browserSelected(let browser):
            return (state.copy(selectedBrowser: .replacing(with: browser)), .saveBrowser(browser))

        case .openTapped(let linkID):
            guard let link = state.link(linkID) else { return (state, nil) }
            return (state, .open(url: link.url, browser: state.selectedBrowser))

        case .notificationTapped(let linkID):
            guard let link = state.link(linkID), link.state == .online else { return (state, nil) }
            return (state, .open(url: link.url, browser: state.selectedBrowser))

        case .pauseToggled(let linkID):
            guard let link = state.link(linkID) else { return (state, nil) }
            guard !link.isPaused else {
                return (state, .resumeMonitoring(linkID: linkID, url: link.url))
            }
            return (state.updatingLink(linkID) { $0.paused() }, .stopMonitoring(linkID: linkID))

        case .muteToggled(let linkID):
            guard state.link(linkID) != nil else { return (state, nil) }
            return (state.updatingLink(linkID) { $0.togglingMute() }, .saveWatchlist)

        case .resetStatisticsTapped(let linkID):
            return (state.updatingLink(linkID) { $0.resettingStatistics() }, nil)

        case .removeTapped(let linkID):
            return (state.copy(links: state.links.filter { $0.id != linkID }), .stopMonitoring(linkID: linkID))

        case .linkMoved(let linkID, let targetID):
            guard linkID != targetID,
                  let from = state.links.firstIndex(where: { $0.id == linkID }),
                  let to = state.links.firstIndex(where: { $0.id == targetID })
            else { return (state, nil) }
            var links = state.links
            links.insert(links.remove(at: from), at: to)
            return (state.copy(links: links), .saveWatchlist)

        case .networkAvailabilityChanged(let isAvailable):
            return (state.copy(isNetworkAvailable: isAvailable), nil)

        case ._loaded(let browsers, let savedBrowserAppURL):
            let savedBrowser = browsers.first { $0.appURL == savedBrowserAppURL }
            return (state.copy(browsers: browsers, selectedBrowser: .replacing(with: savedBrowser)), nil)

        case ._linkAdded(let link):
            return (state.copy(links: state.links + [link]), nil)

        case ._monitoringResumed(let linkID, let date):
            return (state.updatingLink(linkID) { $0.resumed(at: date) }, nil)

        case ._monitorUpdated(let linkID, let update, let date):
            return reduceMonitorUpdate(state: state, linkID: linkID, update: update, date: date)
        }
    }

    private func reduceAdd(state: Domain.State) -> (Domain.State, Domain.Effect?) {
        guard state.canAdd else { return (state, nil) }

        guard let url = LinkInputParser.parse(state.inputText) else {
            return (state.copy(inputError: .set(.invalidURL)), nil)
        }
        guard !state.links.contains(where: { $0.url == url }) else {
            return (state.copy(inputError: .set(.alreadyWatching)), nil)
        }

        return (state.copy(inputText: "", inputError: .clear), .startMonitoring(url: url))
    }

    private func reduceMonitorUpdate(
        state: Domain.State,
        linkID: UUID,
        update: MonitorUpdate,
        date: Date
    ) -> (Domain.State, Domain.Effect?) {
        // A paused link may still receive one in-flight update before its task is cancelled.
        guard let link = state.link(linkID), !link.isPaused else { return (state, nil) }

        let updated = link.applying(update, at: date)
        let newState = state.updatingLink(linkID) { _ in updated }

        guard !link.isMuted else { return (newState, nil) }

        switch update.transition {
        case .cameOnline:
            let downtime = updated.stateSince.timeIntervalSince(link.stateSince)
            return (newState, .notify(ConnectionAlert(linkID: linkID, url: link.url, kind: .cameOnline(downtime: downtime))))

        case .wentOffline:
            let reason = update.result.offlineReason ?? .other("No response")
            return (newState, .notify(ConnectionAlert(linkID: linkID, url: link.url, kind: .wentOffline(reason))))

        case nil:
            return (newState, nil)
        }
    }
}

nonisolated private extension Patch {
    static func replacing(with value: T?) -> Patch<T> {
        value.map { .set($0) } ?? .clear
    }
}
