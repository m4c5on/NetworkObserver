import Foundation

nonisolated struct Browser: Identifiable, Hashable, Sendable {
    let appURL: URL
    let name: String

    var id: URL { appURL }
}
