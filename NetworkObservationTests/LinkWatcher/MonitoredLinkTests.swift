import Foundation
import Testing
@testable import NetworkObservation

struct MonitoredLinkTests {
    private let start = Date(timeIntervalSince1970: 1_000)

    @Test func downtimeStartsAtFirstFailedProbeNotAtConfirmation() throws {
        let firstFailure = start.addingTimeInterval(60)
        let confirmation = firstFailure.addingTimeInterval(3)

        let link = try makeLink()
            .applying(update(.up(statusCode: 200, latency: .milliseconds(100)), .unknown, verifying: true), at: start)
            .applying(update(.up(statusCode: 200, latency: .milliseconds(100)), .online), at: start.addingTimeInterval(3))
            .applying(update(.down(.timeout), .online, verifying: true), at: firstFailure)
            .applying(update(.down(.timeout), .offline, transition: .wentOffline), at: confirmation)

        #expect(link.state == .offline)
        #expect(link.stateSince == firstFailure)
        #expect(link.pendingSince == nil)
        #expect(link.consecutiveFailures == 2)
        #expect(link.statistics.outages == 1)
    }

    @Test func statisticsTrackUptimeAndAverageLatency() {
        let statistics = LinkStatistics.empty
            .recording(.up(statusCode: 200, latency: .milliseconds(100)), startedOutage: false)
            .recording(.up(statusCode: 200, latency: .milliseconds(300)), startedOutage: false)
            .recording(.down(.timeout), startedOutage: true)
            .recording(.up(statusCode: 200, latency: .milliseconds(200)), startedOutage: false)

        #expect(statistics.totalChecks == 4)
        #expect(statistics.uptimeRatio == 0.75)
        #expect(statistics.averageLatency == .milliseconds(200))
        #expect(statistics.outages == 1)
    }

    @Test func historyKeepsOnlyRecentSamples() {
        var statistics = LinkStatistics.empty
        for _ in 0..<(LinkStatistics.historyLimit + 5) {
            statistics = statistics.recording(.down(.timeout), startedOutage: false)
        }

        #expect(statistics.recentSamples.count == LinkStatistics.historyLimit)
        #expect(statistics.totalChecks == LinkStatistics.historyLimit + 5)
    }

    private func makeLink() throws -> MonitoredLink {
        .new(id: UUID(), url: try #require(URL(string: "https://staging.example.com")), startedAt: start)
    }

    private func update(
        _ result: CheckResult,
        _ state: ConnectionState,
        verifying: Bool = false,
        transition: ConnectionTransition? = nil
    ) -> MonitorUpdate {
        MonitorUpdate(result: result, state: state, isVerifying: verifying, transition: transition)
    }
}
