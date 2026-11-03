import Foundation
import Testing
@testable import NetworkObservation

@MainActor
struct NetworkOutageTrackerTests {
    private let start = Date(timeIntervalSince1970: 1_000)

    @Test func healthyReadingsProduceNoEvent() {
        var tracker = NetworkOutageTracker()

        #expect(tracker.register(healthState: .good, externalResult: .ok, at: start) == nil)
        #expect(tracker.register(healthState: .degraded, externalResult: .slow, at: start) == nil)
    }

    @Test func unreachableRouterAloneIsNotAnInternetOutage() {
        var tracker = NetworkOutageTracker()

        #expect(tracker.register(healthState: .unreachable, externalResult: .ok, at: start) == nil)
    }

    @Test func unreachableWithFailingInternetIsAnOutage() {
        var tracker = NetworkOutageTracker()

        #expect(tracker.register(healthState: .unreachable, externalResult: .failing, at: start) == .wentDown)
    }

    @Test func noNetworkInterfaceIsAnOutage() {
        var tracker = NetworkOutageTracker()

        #expect(tracker.register(healthState: .noNetwork, externalResult: nil, at: start) == .wentDown)
    }

    @Test func permissionNeededIsNotAnOutage() {
        var tracker = NetworkOutageTracker()

        #expect(tracker.register(healthState: .permissionNeeded, externalResult: nil, at: start) == nil)
    }

    @Test func outageIsReportedOnlyOnce() {
        var tracker = NetworkOutageTracker()
        _ = tracker.register(healthState: .unreachable, externalResult: .failing, at: start)

        #expect(tracker.register(healthState: .noNetwork, externalResult: nil, at: start.addingTimeInterval(5)) == nil)
    }

    /// The external result is a raw per-cycle reading while the health state is debounced, so a
    /// single good cycle must not end the outage.
    @Test func outageLastsUntilTheDebouncedHealthStateRecovers() {
        var tracker = NetworkOutageTracker()
        _ = tracker.register(healthState: .unreachable, externalResult: .failing, at: start)

        #expect(tracker.register(healthState: .unreachable, externalResult: .ok, at: start.addingTimeInterval(5)) == nil)
        #expect(tracker.register(healthState: .good, externalResult: .ok, at: start.addingTimeInterval(65)) == .cameBack(downtime: 65))
    }

    @Test func degradedConnectionEndsTheOutage() {
        var tracker = NetworkOutageTracker()
        _ = tracker.register(healthState: .noNetwork, externalResult: nil, at: start)

        #expect(tracker.register(healthState: .badlyDegraded, externalResult: .slow, at: start.addingTimeInterval(10)) == .cameBack(downtime: 10))
    }
}
