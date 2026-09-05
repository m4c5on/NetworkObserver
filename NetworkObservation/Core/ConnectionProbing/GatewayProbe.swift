//
//  GatewayProbe.swift
//  NetworkObservation
//
//  ICMP echo probe (ADR-0004 Option 1 — unprivileged SOCK_DGRAM/IPPROTO_ICMP,
//  confirmed viable on unsandboxed macOS by the T1 spike).
//

import Foundation
import Darwin

struct GatewayProbe {
    struct Result: Equatable {
        let reachable: Bool
        let latencyMs: Double?
    }

    let timeout: TimeInterval

    init(timeout: TimeInterval = 2) {
        self.timeout = timeout
    }

    func probe(host: String) async -> Result {
        let timeout = timeout
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: Self.performEchoProbe(host: host, timeout: timeout))
            }
        }
    }

    private static func performEchoProbe(host: String, timeout: TimeInterval) -> Result {
        let sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)
        guard sock >= 0 else { return Result(reachable: false, latencyMs: nil) }
        defer { close(sock) }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        guard inet_pton(AF_INET, host, &addr.sin_addr) == 1 else {
            return Result(reachable: false, latencyMs: nil)
        }

        // A random identifier (not the shared process id) so concurrent probes on distinct
        // sockets can't have their replies cross-delivered by the kernel's ICMP demux.
        let identifier = UInt16.random(in: UInt16.min...UInt16.max)
        let packet = echoRequestPacket(identifier: identifier, sequence: 1)

        let start = DispatchTime.now()

        let sendResult = packet.withUnsafeBytes { buf -> Int in
            withUnsafePointer(to: &addr) { addrPtr -> Int in
                addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                    sendto(sock, buf.baseAddress, buf.count, 0, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }
        guard sendResult > 0 else { return Result(reachable: false, latencyMs: nil) }

        // A single deadline for the whole wait: an ICMP error bounce (e.g. "destination
        // unreachable" from a router with no route) can arrive almost instantly and must not
        // be mistaken for our echo reply — if that happens, keep polling for the real reply
        // (or a genuine timeout) instead of returning early.
        let deadline = DispatchTime.now() + timeout

        while true {
            let remainingMs = Int32((Double(deadline.uptimeNanoseconds) - Double(DispatchTime.now().uptimeNanoseconds)) / 1_000_000)
            guard remainingMs > 0 else { return Result(reachable: false, latencyMs: nil) }

            var pfd = pollfd(fd: sock, events: Int16(POLLIN), revents: 0)
            let pollResult = poll(&pfd, 1, remainingMs)
            guard pollResult > 0 else { return Result(reachable: false, latencyMs: nil) }

            var recvBuf = [UInt8](repeating: 0, count: 128)
            let bytesReceived = recv(sock, &recvBuf, recvBuf.count, 0)
            guard bytesReceived > 0 else { return Result(reachable: false, latencyMs: nil) }

            // macOS prepends the IP header even on a SOCK_DGRAM ICMP socket's received
            // datagram; the IHL (low nibble of the first byte) gives its length in 32-bit words.
            let ipHeaderLength = Int(recvBuf[0] & 0x0F) * 4
            let icmpOffset = ipHeaderLength
            guard bytesReceived >= icmpOffset + 8 else { continue }

            let type = recvBuf[icmpOffset]
            let replyIdentifier = UInt16(recvBuf[icmpOffset + 4]) << 8 | UInt16(recvBuf[icmpOffset + 5])
            guard type == 0, replyIdentifier == identifier else {
                // Not our echo reply (an ICMP error bounce, or someone else's packet) — keep waiting.
                continue
            }

            let elapsedNs = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
            let latencyMs = Double(elapsedNs) / 1_000_000
            return Result(reachable: true, latencyMs: latencyMs)
        }
    }

    private static func echoRequestPacket(identifier: UInt16, sequence: UInt16) -> [UInt8] {
        var packet: [UInt8] = [
            8, 0, // type = echo request, code = 0
            0, 0, // checksum placeholder
            UInt8(identifier >> 8), UInt8(identifier & 0xFF),
            UInt8(sequence >> 8), UInt8(sequence & 0xFF),
        ]
        let checksum = icmpChecksum(packet)
        packet[2] = UInt8(checksum >> 8)
        packet[3] = UInt8(checksum & 0xFF)
        return packet
    }

    private static func icmpChecksum(_ data: [UInt8]) -> UInt16 {
        var sum: UInt32 = 0
        var index = 0
        while index < data.count - 1 {
            sum += UInt32(data[index]) << 8 | UInt32(data[index + 1])
            index += 2
        }
        if index < data.count {
            sum += UInt32(data[index]) << 8
        }
        while sum >> 16 != 0 {
            sum = (sum & 0xFFFF) + (sum >> 16)
        }
        return ~UInt16(sum & 0xFFFF)
    }
}
