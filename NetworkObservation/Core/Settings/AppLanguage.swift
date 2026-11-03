//
//  AppLanguage.swift
//  NetworkObservation
//
//  The interface language chosen in Settings > General. It is stored the way macOS stores a
//  per-app language (AppleLanguages in the app's own defaults), so it applies on the next launch.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case ukrainian = "uk"
    case belarusian = "be"
    case russian = "ru"
    case polish = "pl"

    var id: String { rawValue }

    /// Each language is named in itself, so it can be found whatever language the app is in.
    var nativeName: String? {
        switch self {
        case .system: nil
        case .english: "English"
        case .ukrainian: "Українська"
        case .belarusian: "Беларуская"
        case .russian: "Русский"
        case .polish: "Polski"
        }
    }
}

struct AppLanguageSettings {
    private static let key = "AppleLanguages"

    private let defaults: UserDefaults
    private let domainName: String

    init(defaults: UserDefaults = .standard, domainName: String = Bundle.main.bundleIdentifier ?? "") {
        self.defaults = defaults
        self.domainName = domainName
    }

    /// Only the app's own choice counts — the system-wide list also lives under the same key.
    var current: AppLanguage {
        guard let code = (defaults.persistentDomain(forName: domainName)?[Self.key] as? [String])?.first else {
            return .system
        }
        return AppLanguage.allCases.first { $0 != .system && (code == $0.rawValue || code.hasPrefix($0.rawValue + "-")) } ?? .system
    }

    func set(_ language: AppLanguage) {
        if language == .system {
            defaults.removeObject(forKey: Self.key)
        } else {
            defaults.set([language.rawValue], forKey: Self.key)
        }
    }
}
