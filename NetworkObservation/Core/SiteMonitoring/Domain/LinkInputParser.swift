import Foundation

nonisolated enum LinkInputParser {
    private static let supportedSchemes: Set<String> = ["http", "https"]

    /// Accepts "staging.example.com", "http://localhost:3000/health", etc. Defaults to https when no scheme is given.
    static func parse(_ rawInput: String) -> URL? {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(where: \.isWhitespace) else { return nil }

        let candidate = trimmed.contains("://") ? trimmed : "https://" + trimmed

        guard
            let components = URLComponents(string: candidate),
            let scheme = components.scheme?.lowercased(),
            supportedSchemes.contains(scheme),
            let host = components.host,
            !host.isEmpty,
            let url = components.url
        else { return nil }

        return url
    }
}
