import Foundation
import Testing
@testable import NetworkObservation

@MainActor
struct AppLanguageSettingsTests {
    private let suiteName = "AppLanguageSettingsTests-\(UUID().uuidString)"

    private func makeSettings() -> (AppLanguageSettings, UserDefaults) {
        let defaults = UserDefaults(suiteName: suiteName)!
        return (AppLanguageSettings(defaults: defaults, domainName: suiteName), defaults)
    }

    @Test func followsTheSystemUntilALanguageIsChosen() {
        let (settings, _) = makeSettings()

        #expect(settings.current == .system)
    }

    @Test(arguments: [AppLanguage.english, .ukrainian, .belarusian, .russian, .polish])
    func choosingALanguageOverridesTheAppsPreferredLanguages(_ language: AppLanguage) {
        let (settings, defaults) = makeSettings()

        settings.set(language)

        #expect(settings.current == language)
        #expect(defaults.stringArray(forKey: "AppleLanguages") == [language.rawValue])
    }

    @Test func choosingSystemRemovesTheOverride() {
        let (settings, defaults) = makeSettings()
        settings.set(.polish)

        settings.set(.system)

        #expect(settings.current == .system)
        #expect(defaults.persistentDomain(forName: suiteName)?["AppleLanguages"] == nil)
    }

    @Test func recognisesARegionalLanguageCode() {
        let (settings, defaults) = makeSettings()
        defaults.set(["uk-UA"], forKey: "AppleLanguages")

        #expect(settings.current == .ukrainian)
    }

    @Test func everyLanguageIsNamedInItself() {
        #expect(AppLanguage.ukrainian.nativeName == "Українська")
        #expect(AppLanguage.belarusian.nativeName == "Беларуская")
        #expect(AppLanguage.polish.nativeName == "Polski")
        #expect(AppLanguage.system.nativeName == nil)
    }
}
