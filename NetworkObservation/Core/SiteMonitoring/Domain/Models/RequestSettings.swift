import Foundation

/// DELETE is left out on purpose: repeating it every 15 seconds would destroy data.
nonisolated enum HTTPMethod: String, Codable, CaseIterable, Identifiable, Sendable {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case options = "OPTIONS"

    var id: String { rawValue }
}

/// How a link is checked: which request is sent and which responses count as "online".
nonisolated struct RequestSettings: Codable, Equatable, Sendable {
    let method: HTTPMethod
    /// Sorted, unique, non-empty, each in 100...599.
    let acceptedStatusCodes: [Int]

    static let `default` = RequestSettings(method: .get, acceptedStatusCodes: [200])

    var acceptedStatusCodesText: String {
        acceptedStatusCodes.map(String.init).joined(separator: ", ")
    }

    /// Accepts codes separated by commas, semicolons or spaces, e.g. "200, 401".
    /// Returns nil when the text is empty or anything in it is not a valid HTTP status code.
    static func parseStatusCodes(_ text: String) -> [Int]? {
        let tokens = text
            .split(whereSeparator: { $0 == "," || $0 == ";" || $0.isWhitespace })
            .map(String.init)
        guard !tokens.isEmpty else { return nil }

        var codes = Set<Int>()
        for token in tokens {
            guard let code = Int(token), (100...599).contains(code) else { return nil }
            codes.insert(code)
        }
        return codes.sorted()
    }
}
