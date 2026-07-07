import AppKit
import SwiftUI
import SwiftData

final class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var updateTimer: Timer?
    private weak var appState: AppState?

    func setup(appState: AppState, container: ModelContainer) {
        self.appState = appState

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Zen")
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        let content = MenuBarPanel()
            .environment(appState)
            .modelContainer(container)
        let hosting = NSHostingController(rootView: content)
        hosting.sizingOptions = .preferredContentSize

        let pop = NSPopover()
        pop.contentViewController = hosting
        pop.behavior = .transient
        pop.animates = false
        popover = pop

        updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshLabel()
        }
        RunLoop.main.add(updateTimer!, forMode: .common)
        refreshLabel()
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func refreshLabel() {
        guard let button = statusItem?.button, let vm = appState?.timerVM else { return }
        let remaining = vm.remainingSeconds()
        let total = max(0, Int(remaining))
        let timeStr = String(format: "%02d:%02d", total / 60, total % 60)

        switch vm.runState {
        case .idle, .completed:
            button.attributedTitle = NSAttributedString(string: "")
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Zen")
        case .running:
            button.image = nil
            button.attributedTitle = NSAttributedString(
                string: "● \(timeStr)",
                attributes: [.foregroundColor: NSColor.labelColor]
            )
        case .paused:
            button.image = nil
            button.attributedTitle = NSAttributedString(
                string: "⏸ \(timeStr)",
                attributes: [.foregroundColor: NSColor.secondaryLabelColor]
            )
        }
    }

    deinit {
        updateTimer?.invalidate()
        if let item = statusItem { NSStatusBar.system.removeStatusItem(item) }
    }
}
