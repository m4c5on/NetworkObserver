//
//  ConnectionHealthPresentation.swift
//  NetworkObservation
//
//  Colors, status-bar symbols and explanation texts for the health states — shared by the
//  status-bar popover, the main window panel and Settings.
//

import AppKit
import SwiftUI

/// Bridges the user-configurable health-tier colors (stored as hex strings in
/// ConnectionHealthSettings) to SwiftUI's Color for display and back for persistence.
extension Color {
    init?(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    /// nil if the color can't be resolved into the sRGB space (e.g. a pattern/dynamic color).
    var hexString: String? {
        guard let rgb = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = Int((rgb.redComponent * 255).rounded())
        let g = Int((rgb.greenComponent * 255).rounded())
        let b = Int((rgb.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension ConnectionHealthDomain.State {
    /// Falls back to the pastel defaults if the stored hex is somehow unparseable.
    var goodColor: Color { Color(hex: goodColorHex) ?? Color(hex: ConnectionHealthSettings.defaultGoodColorHex)! }
    var degradedColor: Color { Color(hex: degradedColorHex) ?? Color(hex: ConnectionHealthSettings.defaultDegradedColorHex)! }
    var badColor: Color { Color(hex: badColorHex) ?? Color(hex: ConnectionHealthSettings.defaultBadColorHex)! }
}

extension ConnectionHealthDomain.HealthState {
    /// AC-01/AC-06/AC-08: good/degraded/unreachable are distinct; AC-03 keeps permission-needed
    /// on the unreachable color (distinguished by menu text, not color); AC-07 keeps no-network
    /// a fourth, distinct color. Colors are user-configurable (Settings), so they're passed in
    /// rather than hardcoded.
    func statusBarColor(good: Color, degraded: Color, bad: Color) -> Color {
        switch self {
        case .good: return good
        case .degraded: return degraded
        case .badlyDegraded, .unreachable, .permissionNeeded: return bad
        case .noNetwork: return .gray
        }
    }

    var statusBarSymbolName: String {
        switch self {
        case .good: return "network"
        case .degraded: return "network"
        case .badlyDegraded: return "network"
        case .unreachable: return "xmark.circle.fill"
        case .permissionNeeded: return "lock.circle.fill"
        case .noNetwork: return "network.slash"
        }
    }

    /// NSStatusItem auto-templates SF Symbol images (alpha-only, no color), so SwiftUI's
    /// foregroundStyle/renderingMode modifiers on the MenuBarExtra label are ignored. Building
    /// the NSImage directly and forcing isTemplate = false is the only way to keep the color.
    func statusBarImage(good: Color, degraded: Color, bad: Color) -> NSImage {
        let configuration = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
            .applying(NSImage.SymbolConfiguration(paletteColors: [NSColor(statusBarColor(good: good, degraded: degraded, bad: bad))]))
        let image = NSImage(systemSymbolName: statusBarSymbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
        image?.isTemplate = false
        return image ?? NSImage()
    }

    /// AC-03/AC-03b/AC-07: menu text that disambiguates states sharing a color, or a plain
    /// no-network cause, from a genuine unreachable reading.
    var menuExplanation: String {
        switch self {
        case .good: return "Connection is healthy."
        case .degraded: return "Connection is degraded."
        case .badlyDegraded: return "Connection is badly degraded."
        case .unreachable: return "Connection is unreachable."
        case .permissionNeeded: return "Local Network permission is required. Grant it in System Settings > Privacy & Security > Local Network."
        case .noNetwork: return "No active network interface (Wi-Fi/Ethernet)."
        }
    }
}
