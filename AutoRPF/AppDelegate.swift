import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, SettingsWindowControllerDelegate {
    private let store = SettingsStore()
    private let tunnelManager = TunnelManager()
    private var statusItem: NSStatusItem?
    private var settingsWindowController: SettingsWindowController?
    private var configTargets: [SSHConfigTarget] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        tunnelManager.onStateChanged = { [weak self] _ in
            self?.rebuildMenu()
        }
        refreshTargets()
        configureStatusItem()
        rebuildMenu()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func settingsDidChange() {
        rebuildMenu()
    }

    func settingsWindowDidClose() {
        settingsWindowController = nil
        NSApp.setActivationPolicy(.accessory)
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.toolTip = "AutoRPF"
        let image = NSImage(systemSymbolName: "arrow.left.arrow.right.circle.fill", accessibilityDescription: "AutoRPF")
        image?.isTemplate = true
        image?.size = NSSize(width: 18, height: 18)
        item.button?.image = image
        item.button?.imagePosition = .imageLeft
        statusItem = item
        updateStatusItemPresentation()
    }

    private func rebuildMenu() {
        updateStatusItemPresentation()

        let menu = NSMenu()
        menu.addItem(disabledItem(title: statusTitle))
        menu.addItem(disabledItem(title: portTitle))
        menu.addItem(.separator())

        let toggleItem = NSMenuItem(
            title: isRunning ? "Stop Tunnel" : "Start Tunnel",
            action: #selector(toggleTunnel),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.isEnabled = currentTarget.isRunnable || isRunning
        menu.addItem(toggleItem)

        menu.addItem(.separator())
        let targetsItem = NSMenuItem(title: "SSH Targets", action: nil, keyEquivalent: "")
        targetsItem.submenu = buildTargetsMenu()
        menu.addItem(targetsItem)

        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(title: "Quit AutoRPF", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    private func buildTargetsMenu() -> NSMenu {
        let menu = NSMenu()

        if configTargets.isEmpty {
            menu.addItem(disabledItem(title: "No SSH config targets"))
        } else {
            for target in configTargets {
                let item = NSMenuItem(title: target.alias, action: #selector(selectConfigTarget(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = target.alias
                item.state = store.selectedTargetKind == "config" && selectedConfigAlias == target.alias ? .on : .off
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())

        let customItem = NSMenuItem(title: customTargetTitle, action: #selector(selectCustomTarget), keyEquivalent: "")
        customItem.target = self
        customItem.state = store.selectedTargetKind == "custom" ? .on : .off
        menu.addItem(customItem)

        menu.addItem(.separator())

        let refreshItem = NSMenuItem(title: "Refresh SSH Config", action: #selector(refreshTargetsAction), keyEquivalent: "")
        refreshItem.target = self
        menu.addItem(refreshItem)

        return menu
    }

    private func updateStatusItemPresentation() {
        guard let statusItem else { return }

        if store.showRunningTargetInMenuBar, let runningTargetName {
            statusItem.length = NSStatusItem.variableLength
            statusItem.button?.title = " \(runningTargetName)"
        } else {
            statusItem.length = NSStatusItem.squareLength
            statusItem.button?.title = ""
        }
    }

    private var currentTarget: TunnelTarget {
        if store.selectedTargetKind == "config",
           let selectedConfigAlias,
           let target = configTargets.first(where: { $0.alias == selectedConfigAlias }) {
            return .config(target)
        }
        return .custom(store.customTarget)
    }

    private var selectedConfigAlias: String? {
        store.selectedTargetAlias
    }

    private var isRunning: Bool {
        if case .running = tunnelManager.state {
            return true
        }
        return false
    }

    private var runningTargetName: String? {
        if case .running(let targetName, _) = tunnelManager.state {
            return targetName
        }
        return nil
    }

    private var statusTitle: String {
        switch tunnelManager.state {
        case .stopped:
            return "Stopped"
        case .running(let targetName, let pid):
            return "Running: \(targetName) (pid \(pid))"
        case .failed(let message):
            return "Error: \(message)"
        }
    }

    private var portTitle: String {
        let ports = store.portSettings
        return "Remote \(ports.remotePort) -> Local \(ports.localPort)"
    }

    private var customTargetTitle: String {
        let target = store.customTarget
        let suffix = target.displayName.isEmpty ? "not configured" : target.displayName
        return "Custom: \(suffix)"
    }

    @objc private func toggleTunnel() {
        if isRunning {
            tunnelManager.stop()
        } else {
            tunnelManager.start(target: currentTarget, ports: store.portSettings)
        }
    }

    @objc private func selectConfigTarget(_ sender: NSMenuItem) {
        guard let alias = sender.representedObject as? String else { return }
        store.selectedTargetKind = "config"
        store.selectedTargetAlias = alias
        if isRunning {
            tunnelManager.start(target: currentTarget, ports: store.portSettings)
        }
        rebuildMenu()
    }

    @objc private func selectCustomTarget() {
        store.selectedTargetKind = "custom"
        if isRunning {
            tunnelManager.start(target: currentTarget, ports: store.portSettings)
        }
        rebuildMenu()
    }

    @objc private func refreshTargetsAction() {
        refreshTargets()
        rebuildMenu()
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            let controller = SettingsWindowController(store: store)
            controller.delegate = self
            settingsWindowController = controller
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(nil)
    }

    @objc private func quit() {
        tunnelManager.stop()
        NSApp.terminate(nil)
    }

    private func refreshTargets() {
        let configURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".ssh")
            .appendingPathComponent("config")
        configTargets = SSHConfigParser.parseFile(at: configURL)

        if store.selectedTargetKind == "config",
           let alias = store.selectedTargetAlias,
           !configTargets.contains(where: { $0.alias == alias }) {
            store.selectedTargetKind = "custom"
        }
    }

    private func disabledItem(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}
