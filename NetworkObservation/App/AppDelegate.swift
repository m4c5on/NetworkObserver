//
//  AppDelegate.swift
//  NetworkObservation
//
//  A regular Dock app that also lives in the status bar: closing the main window keeps both
//  monitors running, and clicking the Dock icon brings the window back.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = AppCoordinator.live()

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        coordinator.appBecameActive()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            coordinator.openMainWindow?()
        }
        return true
    }
}
