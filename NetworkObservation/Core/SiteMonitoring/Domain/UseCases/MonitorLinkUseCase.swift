import Foundation

nonisolated protocol MonitorLinkUseCase: Sendable {
    /// Polls `url` indefinitely. Cancelling the consuming task stops polling immediately.
    func execute(url: URL, request: RequestSettings, pollInterval: Duration) -> AsyncStream<MonitorUpdate>
}

nonisolated struct DefaultMonitorLinkUseCase: MonitorLinkUseCase {
    private let checker: any ReachabilityChecker
    private let policy: WatchPolicy
    /// Asked after a failed check: a failure while this Mac itself is offline says nothing about
    /// the site, so it is not counted (no state change, no statistics, no notification).
    private let internetReachable: @Sendable () async -> Bool
    private let sleep: @Sendable (Duration) async throws -> Void

    init(
        checker: any ReachabilityChecker,
        policy: WatchPolicy = .default,
        internetReachable: @escaping @Sendable () async -> Bool = { true },
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.checker = checker
        self.policy = policy
        self.internetReachable = internetReachable
        self.sleep = sleep
    }

    func execute(url: URL, request: RequestSettings, pollInterval: Duration) -> AsyncStream<MonitorUpdate> {
        let (stream, continuation) = AsyncStream.makeStream(of: MonitorUpdate.self)
        let task = Task {
            await run(url: url, request: request, pollInterval: pollInterval, continuation: continuation)
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }

    private func run(
        url: URL,
        request: RequestSettings,
        pollInterval: Duration,
        continuation: AsyncStream<MonitorUpdate>.Continuation
    ) async {
        var machine = ConnectionStateMachine()

        while !Task.isCancelled {
            let result = evaluate(await checker.check(url, method: request.method), acceptedStatusCodes: request.acceptedStatusCodes)
            guard !Task.isCancelled else { return }

            if !result.isUp, !(await internetReachable()) {
                guard await pause(for: pollInterval) else { return }
                continue
            }

            let transition = machine.register(isUp: result.isUp)
            continuation.yield(MonitorUpdate(
                result: result,
                state: machine.confirmed,
                isVerifying: machine.isVerifying,
                transition: transition
            ))

            let delay = machine.isVerifying ? policy.confirmationDelay : pollInterval
            guard await pause(for: delay) else { return }
        }
    }

    private func evaluate(_ outcome: CheckOutcome, acceptedStatusCodes: [Int]) -> CheckResult {
        switch outcome {
        case .responded(let statusCode, let latency) where acceptedStatusCodes.contains(statusCode):
            .up(statusCode: statusCode, latency: latency)
        case .responded(let statusCode, _):
            .down(.httpStatus(statusCode))
        case .failed(let reason):
            .down(reason)
        }
    }

    /// Returns `false` when the sleep was cancelled.
    private func pause(for duration: Duration) async -> Bool {
        do {
            try await sleep(duration)
            return !Task.isCancelled
        } catch {
            return false
        }
    }
}
