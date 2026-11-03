/// The poll interval is a user setting (Settings > Sites) and is passed to each monitoring run.
nonisolated struct WatchPolicy: Equatable, Sendable {
    let confirmationDelay: Duration

    init(confirmationDelay: Duration = .seconds(3)) {
        self.confirmationDelay = confirmationDelay
    }

    static let `default` = WatchPolicy()
}
