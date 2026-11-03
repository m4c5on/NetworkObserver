import Foundation

nonisolated enum DisplayFormatting {
    static func elapsed(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%d:%02d", minutes, seconds)
    }

    static func latency(_ duration: Duration) -> String {
        let milliseconds = duration.inMilliseconds
        return milliseconds < 1000
            ? String(localized: "\(Int(milliseconds.rounded())) ms")
            : String(localized: "\(String(format: "%.1f", milliseconds / 1000)) s")
    }

    static func percent(_ ratio: Double) -> String {
        ratio >= 0.9995 ? "100%" : String(format: "%.1f%%", ratio * 100)
    }
}

nonisolated extension Duration {
    var inMilliseconds: Double {
        Double(components.seconds) * 1000 + Double(components.attoseconds) / 1e15
    }
}

nonisolated extension OfflineReason {
    var displayText: String {
        switch self {
        case .httpStatus(let code): String(localized: "HTTP \(code)")
        case .timeout: String(localized: "Timed out")
        case .hostNotFound: String(localized: "Host not found — VPN?")
        case .cannotConnect: String(localized: "Can't connect")
        case .noInternet: String(localized: "No internet")
        case .secureConnectionFailed: String(localized: "TLS error")
        case .other(let message): message
        }
    }
}
