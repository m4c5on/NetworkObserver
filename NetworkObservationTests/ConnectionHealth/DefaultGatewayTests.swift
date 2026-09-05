//
//  DefaultGatewayTests.swift
//  NetworkObservationTests
//

import Testing
import Darwin
@testable import NetworkObservation

struct DefaultGatewayTests {

    @Test func returnsAParseableIPv4AddressOnThisDevelopmentMachine() {
        let address = DefaultGateway.ipv4Address()
        #expect(address != nil)
        if let address {
            var addr = in_addr()
            #expect(inet_pton(AF_INET, address, &addr) == 1)
        }
    }
}
