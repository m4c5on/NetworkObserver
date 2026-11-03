nonisolated struct WatchPolicy: Equatable, Sendable {
    let pollInterval: Duration
    let confirmationDelay: Duration
    let acceptedStatusCodes: Set<Int>

    init(
        pollInterval: Duration = .seconds(15),
        confirmationDelay: Duration = .seconds(3),
        acceptedStatusCodes: Set<Int> = [200]
    ) {
        self.pollInterval = pollInterval
        self.confirmationDelay = confirmationDelay
        self.acceptedStatusCodes = acceptedStatusCodes
    }

    static let `default` = WatchPolicy()
}
