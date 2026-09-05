//
//  NetworkInterfaceMonitorTests.swift
//  NetworkObservationTests
//

import Testing
@testable import NetworkObservation

struct NetworkInterfaceMonitorTests {

    typealias Interface = NetworkInterfaceMonitor.Interface

    @Test func noInterfacesAtAllMeansNoActiveNetwork() {
        #expect(NetworkInterfaceMonitor.hasActiveInterface(among: []) == false)
    }

    @Test func onlyLoopbackUpDoesNotCountAsActiveNetwork() {
        let interfaces = [Interface(name: "lo0", isUp: true, isRunning: true, isLoopback: true)]
        #expect(NetworkInterfaceMonitor.hasActiveInterface(among: interfaces) == false)
    }

    @Test func anUpAndRunningNonLoopbackInterfaceIsActive() {
        let interfaces = [
            Interface(name: "lo0", isUp: true, isRunning: true, isLoopback: true),
            Interface(name: "en0", isUp: true, isRunning: true, isLoopback: false),
        ]
        #expect(NetworkInterfaceMonitor.hasActiveInterface(among: interfaces) == true)
    }

    @Test func anUpButNotRunningInterfaceLikeAnUnpluggedCableIsNotActive() {
        let interfaces = [Interface(name: "en0", isUp: true, isRunning: false, isLoopback: false)]
        #expect(NetworkInterfaceMonitor.hasActiveInterface(among: interfaces) == false)
    }

    @Test func aUsableRealInterfaceExistsOnThisDevelopmentMachine() {
        // Integration check: this test machine has some active network path (Wi-Fi/Ethernet).
        let monitor = NetworkInterfaceMonitor()
        #expect(monitor.hasActiveInterface() == true)
    }
}
