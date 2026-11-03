//
//  NotificationPreferences.swift
//  NetworkObservation
//
//  Which kinds of notifications the user wants (Settings > Notifications). Every kind is on
//  until switched off; muting a single site is separate (the bell on its card).
//

import Foundation
import Observation

enum NotificationKind: String, CaseIterable, Identifiable {
    case siteDown
    case siteUp
    case internetLost
    case internetRestored

    var id: String { rawValue }

    var title: String {
        switch self {
        case .siteDown: String(localized: "A site goes down")
        case .siteUp: String(localized: "A site is back up")
        case .internetLost: String(localized: "Internet connection lost")
        case .internetRestored: String(localized: "Internet connection restored")
        }
    }
}

extension ConnectionAlert {
    var notificationKind: NotificationKind {
        switch kind {
        case .wentOffline: .siteDown
        case .cameOnline: .siteUp
        }
    }
}

extension NetworkOutageEvent {
    var notificationKind: NotificationKind {
        switch self {
        case .wentDown: .internetLost
        case .cameBack: .internetRestored
        }
    }
}

@Observable
final class NotificationPreferences {
    private static let disabledKindsKey = "notifications.disabledKinds"

    private(set) var disabledKinds: Set<NotificationKind>
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.stringArray(forKey: Self.disabledKindsKey) ?? []
        disabledKinds = Set(stored.compactMap(NotificationKind.init(rawValue:)))
    }

    func isEnabled(_ kind: NotificationKind) -> Bool {
        !disabledKinds.contains(kind)
    }

    func setEnabled(_ isEnabled: Bool, for kind: NotificationKind) {
        if isEnabled {
            disabledKinds.remove(kind)
        } else {
            disabledKinds.insert(kind)
        }
        defaults.set(disabledKinds.map(\.rawValue).sorted(), forKey: Self.disabledKindsKey)
    }
}
