import Testing
@testable import NetworkObservation

struct HTTPStatusDescriptionTests {
    @Test func knownCodesHaveTheirOwnName() {
        #expect(HTTPStatusDescription.name(for: 401) == "Unauthorized")
        #expect(HTTPStatusDescription.name(for: 503) == "Service Unavailable")
    }

    @Test func unknownCodesFallBackToTheirClass() {
        #expect(HTTPStatusDescription.name(for: 299) == "Success")
        #expect(HTTPStatusDescription.name(for: 499) == "Client Error")
        #expect(HTTPStatusDescription.name(for: 599) == "Server Error")
    }

    @Test(arguments: [100, 200, 204, 301, 304, 400, 401, 403, 404, 405, 418, 422, 429, 500, 502, 503, 504, 599])
    func everyCodeHasAnExplanation(_ code: Int) {
        #expect(!HTTPStatusDescription.explanation(for: code).isEmpty)
    }

    @Test func unauthorizedExplainsTheMissingToken() {
        #expect(HTTPStatusDescription.explanation(for: 401).contains("token"))
    }
}
