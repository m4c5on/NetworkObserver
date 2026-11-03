import Foundation
import Testing
@testable import NetworkObservation

struct RequestSettingsTests {
    @Test func defaultIsGetExpecting200() {
        #expect(RequestSettings.default == RequestSettings(method: .get, acceptedStatusCodes: [200]))
    }

    @Test(arguments: [
        ("200, 401", [200, 401]),
        ("401 200 200", [200, 401]),
        (" 204 ", [204]),
        ("200,201;202", [200, 201, 202]),
    ])
    func parsesStatusCodes(text: String, expected: [Int]) {
        #expect(RequestSettings.parseStatusCodes(text) == expected)
    }

    @Test(arguments: ["", "  ", "abc", "200, abc", "99", "600"])
    func rejectsInvalidStatusCodes(_ text: String) {
        #expect(RequestSettings.parseStatusCodes(text) == nil)
    }

    @Test func formatsStatusCodesForEditing() {
        #expect(RequestSettings(method: .post, acceptedStatusCodes: [200, 401]).acceptedStatusCodesText == "200, 401")
    }

    @Test func linksSavedBeforeRequestSettingsExistedLoadWithDefaults() throws {
        let json = Data(#"[{"url":"https://example.com","isPaused":false,"isMuted":true}]"#.utf8)

        let links = try JSONDecoder().decode([StoredLink].self, from: json)

        #expect(links.first?.request == .default)
        #expect(links.first?.isMuted == true)
    }

    @Test func requestSettingsSurviveARoundTrip() throws {
        let url = try #require(URL(string: "https://example.com/account/details"))
        let link = StoredLink(url: url, isPaused: false, isMuted: false, request: RequestSettings(method: .patch, acceptedStatusCodes: [200, 422]))

        let decoded = try JSONDecoder().decode(StoredLink.self, from: JSONEncoder().encode(link))

        #expect(decoded == link)
    }

    @Test func checkResultExposesTheHTTPStatusCode() {
        #expect(CheckResult.up(statusCode: 401, latency: .milliseconds(5)).statusCode == 401)
        #expect(CheckResult.down(.httpStatus(503)).statusCode == 503)
        #expect(CheckResult.down(.timeout).statusCode == nil)
    }
}
