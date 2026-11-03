import Foundation
import Testing
@testable import NetworkObservation

struct FormattingTests {
    @Test(arguments: [
        (0.0, "0:00"),
        (65.0, "1:05"),
        (3_599.0, "59:59"),
        (3_725.0, "1:02:05"),
        (-10.0, "0:00"),
    ])
    func formatsElapsedTime(seconds: TimeInterval, expected: String) {
        #expect(DisplayFormatting.elapsed(seconds) == expected)
    }

    @Test func formatsLatency() {
        #expect(DisplayFormatting.latency(.milliseconds(142)) == "142 ms")
        #expect(DisplayFormatting.latency(.milliseconds(1500)) == "1.5 s")
    }

    @Test func formatsUptime() {
        #expect(DisplayFormatting.percent(1) == "100%")
        #expect(DisplayFormatting.percent(0.9823) == "98.2%")
    }

    @Test func offlineStatusLineShowsDurationFailuresAndReason() throws {
        let start = Date(timeIntervalSince1970: 0)
        let link = MonitoredLink.new(id: UUID(), url: try #require(URL(string: "https://dev.example.com")), startedAt: start)
            .applying(MonitorUpdate(result: .down(.httpStatus(503)), state: .offline, isVerifying: false, transition: nil), at: start)

        let line = LinkWatcherFormatting.statusLine(for: link, now: start.addingTimeInterval(185))

        #expect(line == "Offline for 3:05 · 1 failed check · HTTP 503")
    }

    @Test func summaryCountsPausedLinksSeparately() throws {
        let start = Date(timeIntervalSince1970: 0)
        let url = try #require(URL(string: "https://example.com"))
        let online = MonitoredLink.new(id: UUID(), url: url, startedAt: start)
            .applying(MonitorUpdate(result: .up(statusCode: 200, latency: .milliseconds(10)), state: .online, isVerifying: false, transition: nil), at: start)
        let paused = online.paused()

        #expect(LinkWatcherFormatting.summary(for: [online, paused]) == "1 online · 1 paused")
        #expect(LinkWatcherFormatting.statusLine(for: paused, now: start) == "Paused")
    }
}
