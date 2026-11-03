nonisolated struct WatchPolicy: Equatable, Sendable {
    let pollInterval: Duration
    let confirmationDelay: Duration

    init(
        pollInterval: Duration = .seconds(15),
        confirmationDelay: Duration = .seconds(3)
    ) {
        self.pollInterval = pollInterval
        self.confirmationDelay = confirmationDelay
    }

    static let `default` = WatchPolicy()
}
