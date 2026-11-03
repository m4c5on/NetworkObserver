import Foundation
import Testing
@testable import NetworkObservation

struct MonitorLinkUseCaseTests {
    @Test func reportsTransitionsAndUsesShortDelayWhileVerifying() async throws {
        let url = try #require(URL(string: "https://staging.example.com"))
        let checker = CheckerStub([
            .responded(statusCode: 200, latency: .milliseconds(120)),
            .responded(statusCode: 200, latency: .milliseconds(80)),
            .responded(statusCode: 503, latency: .milliseconds(40)),
            .failed(.timeout),
        ])
        let sleeps = SleepRecorder()
        let useCase = DefaultMonitorLinkUseCase(
            checker: checker,
            policy: WatchPolicy(pollInterval: .seconds(15), confirmationDelay: .seconds(3)),
            sleep: { duration in
                if await sleeps.record(duration) >= 4 { throw CancellationError() }
            }
        )

        let updates = await collect(useCase.execute(url: url))

        #expect(updates.map(\.state) == [.unknown, .online, .online, .offline])
        #expect(updates.map(\.isVerifying) == [true, false, true, false])
        #expect(updates.map(\.transition) == [nil, nil, nil, .wentOffline])
        #expect(updates[2].result == .down(.httpStatus(503)))
        #expect(await sleeps.durations == [.seconds(3), .seconds(15), .seconds(3), .seconds(15)])
    }

    @Test func treatsNonAcceptedSuccessCodesAsDown() async throws {
        let url = try #require(URL(string: "https://staging.example.com"))
        let checker = CheckerStub([.responded(statusCode: 204, latency: .milliseconds(10))])
        let useCase = DefaultMonitorLinkUseCase(checker: checker, sleep: { _ in throw CancellationError() })

        let updates = await collect(useCase.execute(url: url))

        #expect(updates.map(\.result) == [.down(.httpStatus(204))])
    }

    @Test func ignoresFailedChecksWhileTheInternetIsDown() async throws {
        let url = try #require(URL(string: "https://staging.example.com"))
        let checker = CheckerStub([
            .responded(statusCode: 200, latency: .milliseconds(120)),
            .responded(statusCode: 200, latency: .milliseconds(80)),
            .failed(.noInternet),
            .failed(.noInternet),
        ])
        let internet = InternetStub([false, false])
        let sleeps = SleepRecorder()
        let useCase = DefaultMonitorLinkUseCase(
            checker: checker,
            policy: WatchPolicy(pollInterval: .seconds(15), confirmationDelay: .seconds(3)),
            internetReachable: { await internet.next() },
            sleep: { duration in
                if await sleeps.record(duration) >= 4 { throw CancellationError() }
            }
        )

        let updates = await collect(useCase.execute(url: url))

        #expect(updates.map(\.state) == [.unknown, .online])
        #expect(updates.map(\.transition) == [nil, nil])
        #expect(await sleeps.durations == [.seconds(3), .seconds(15), .seconds(15), .seconds(15)])
    }

    @Test func reportsAnOutageThatOutlivesTheInternetOutage() async throws {
        let url = try #require(URL(string: "https://staging.example.com"))
        let checker = CheckerStub([
            .responded(statusCode: 200, latency: .milliseconds(120)),
            .responded(statusCode: 200, latency: .milliseconds(80)),
            .failed(.noInternet),
            .responded(statusCode: 503, latency: .milliseconds(40)),
            .responded(statusCode: 503, latency: .milliseconds(40)),
        ])
        let internet = InternetStub([false, true, true])
        let sleeps = SleepRecorder()
        let useCase = DefaultMonitorLinkUseCase(
            checker: checker,
            policy: WatchPolicy(pollInterval: .seconds(15), confirmationDelay: .seconds(3)),
            internetReachable: { await internet.next() },
            sleep: { duration in
                if await sleeps.record(duration) >= 5 { throw CancellationError() }
            }
        )

        let updates = await collect(useCase.execute(url: url))

        #expect(updates.map(\.state) == [.unknown, .online, .online, .offline])
        #expect(updates.map(\.transition) == [nil, nil, nil, .wentOffline])
    }

    private func collect(_ stream: AsyncStream<MonitorUpdate>) async -> [MonitorUpdate] {
        var updates: [MonitorUpdate] = []
        for await update in stream {
            updates.append(update)
        }
        return updates
    }
}

private actor CheckerStub: ReachabilityChecker {
    private var outcomes: [CheckOutcome]

    init(_ outcomes: [CheckOutcome]) {
        self.outcomes = outcomes
    }

    func check(_ url: URL) async -> CheckOutcome {
        outcomes.isEmpty ? .failed(.other("No more stubbed outcomes")) : outcomes.removeFirst()
    }
}

private actor InternetStub {
    private var answers: [Bool]

    init(_ answers: [Bool]) {
        self.answers = answers
    }

    func next() -> Bool {
        answers.isEmpty ? true : answers.removeFirst()
    }
}

private actor SleepRecorder {
    private(set) var durations: [Duration] = []

    /// Returns the number of recorded sleeps so far.
    func record(_ duration: Duration) -> Int {
        durations.append(duration)
        return durations.count
    }
}
