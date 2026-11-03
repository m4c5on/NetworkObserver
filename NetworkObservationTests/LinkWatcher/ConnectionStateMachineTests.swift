import Testing
@testable import NetworkObservation

struct ConnectionStateMachineTests {
    @Test func firstSuccessIsVerifiedBeforeGoingOnline() {
        var machine = ConnectionStateMachine()

        #expect(machine.register(isUp: true) == nil)
        #expect(machine.confirmed == .unknown)
        #expect(machine.isVerifying)

        #expect(machine.register(isUp: true) == nil)
        #expect(machine.confirmed == .online)
        #expect(!machine.isVerifying)
    }

    @Test func firstFailureGoesOfflineImmediatelyWithoutAlert() {
        var machine = ConnectionStateMachine()

        #expect(machine.register(isUp: false) == nil)
        #expect(machine.confirmed == .offline)
        #expect(!machine.isVerifying)
    }

    @Test func onlineGoesOfflineOnlyAfterTwoFailures() {
        var machine = onlineMachine()

        #expect(machine.register(isUp: false) == nil)
        #expect(machine.confirmed == .online)
        #expect(machine.isVerifying)

        #expect(machine.register(isUp: false) == .wentOffline)
        #expect(machine.confirmed == .offline)
    }

    @Test func singleFailureWhileOnlineIsTreatedAsFlap() {
        var machine = onlineMachine()

        _ = machine.register(isUp: false)
        #expect(machine.register(isUp: true) == nil)
        #expect(machine.confirmed == .online)
        #expect(!machine.isVerifying)
    }

    @Test func offlineComesBackOnlyAfterTwoSuccesses() {
        var machine = ConnectionStateMachine()
        _ = machine.register(isUp: false)

        #expect(machine.register(isUp: true) == nil)
        #expect(machine.isVerifying)
        #expect(machine.register(isUp: true) == .cameOnline)
        #expect(machine.confirmed == .online)
    }

    @Test func failedVerificationWhileUnknownSettlesOffline() {
        var machine = ConnectionStateMachine()
        _ = machine.register(isUp: true)

        #expect(machine.register(isUp: false) == nil)
        #expect(machine.confirmed == .offline)
        #expect(!machine.isVerifying)
    }

    private func onlineMachine() -> ConnectionStateMachine {
        var machine = ConnectionStateMachine()
        _ = machine.register(isUp: true)
        _ = machine.register(isUp: true)
        return machine
    }
}
