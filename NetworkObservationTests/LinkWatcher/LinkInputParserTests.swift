import Foundation
import Testing
@testable import NetworkObservation

struct LinkInputParserTests {
    @Test func addsHTTPSWhenSchemeIsMissing() {
        #expect(LinkInputParser.parse("staging.example.com")?.absoluteString == "https://staging.example.com")
    }

    @Test func keepsExplicitHTTPAndPort() {
        #expect(LinkInputParser.parse("http://localhost:3000/health")?.absoluteString == "http://localhost:3000/health")
    }

    @Test func trimsSurroundingWhitespace() {
        #expect(LinkInputParser.parse("  dev.example.com \n")?.absoluteString == "https://dev.example.com")
    }

    @Test(arguments: ["", "   ", "https://", "ftp://example.com", "exa mple.com"])
    func rejectsInvalidInput(_ input: String) {
        #expect(LinkInputParser.parse(input) == nil)
    }
}
