import Foundation

nonisolated struct URLSessionReachabilityChecker: ReachabilityChecker {
    private let session: URLSession

    init(timeout: TimeInterval = 10) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        session = URLSession(configuration: configuration)
    }

    func check(_ url: URL, method: HTTPMethod) async -> CheckOutcome {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        let clock = ContinuousClock()
        let start = clock.now

        do {
            let (_, response) = try await session.data(for: request)
            let latency = start.duration(to: clock.now)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failed(.other(String(localized: "Not an HTTP response")))
            }
            return .responded(statusCode: httpResponse.statusCode, latency: latency)
        } catch let error as URLError {
            return .failed(OfflineReason(error))
        } catch {
            return .failed(.other(error.localizedDescription))
        }
    }
}

nonisolated extension OfflineReason {
    init(_ error: URLError) {
        switch error.code {
        case .timedOut:
            self = .timeout
        case .cannotFindHost, .dnsLookupFailed:
            self = .hostNotFound
        case .notConnectedToInternet:
            self = .noInternet
        case .cannotConnectToHost, .networkConnectionLost:
            self = .cannotConnect
        case .secureConnectionFailed,
             .serverCertificateUntrusted,
             .serverCertificateHasBadDate,
             .serverCertificateNotYetValid,
             .serverCertificateHasUnknownRoot,
             .clientCertificateRejected,
             .clientCertificateRequired:
            self = .secureConnectionFailed
        default:
            self = .other(error.localizedDescription)
        }
    }
}
