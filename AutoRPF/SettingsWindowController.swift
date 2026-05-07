import AppKit
import ServiceManagement

@MainActor
protocol SettingsWindowControllerDelegate: AnyObject {
    func settingsDidChange()
    func settingsWindowDidClose()
}

final class SettingsWindowController: NSWindowController, NSWindowDelegate, NSTextFieldDelegate {
    weak var delegate: SettingsWindowControllerDelegate?

    private let store: SettingsStore
    private let localPortField = NSTextField()
    private let remotePortField = NSTextField()
    private let syncPortsButton = NSButton(checkboxWithTitle: "Sync ports", target: nil, action: nil)
    private let launchAtLoginButton = NSButton(checkboxWithTitle: "Open AutoRPF at login", target: nil, action: nil)
    private let showRunningTargetButton = NSButton(checkboxWithTitle: "Show running target in menu bar", target: nil, action: nil)
    private let customHostField = NSTextField()
    private let customUserField = NSTextField()
    private let customSSHPortField = NSTextField()
    private let validationLabel = NSTextField(labelWithString: "")

    init(store: SettingsStore) {
        self.store = store
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "AutoRPF Settings"
        window.center()
        super.init(window: window)
        window.delegate = self
        buildUI()
        loadValues()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowWillClose(_ notification: Notification) {
        delegate?.settingsWindowDidClose()
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        saveFromFields()
    }

    func refresh() {
        loadValues()
    }

    private func buildUI() {
        guard let contentView = window?.contentView else { return }

        let title = NSTextField(labelWithString: "AutoRPF")
        title.font = .boldSystemFont(ofSize: 18)

        let subtitle = NSTextField(labelWithString: "Reverse SSH tunnel settings")
        subtitle.textColor = .secondaryLabelColor

        let localLabel = NSTextField(labelWithString: "Local port")
        let remoteLabel = NSTextField(labelWithString: "Remote port")
        let hostLabel = NSTextField(labelWithString: "Custom host")
        let userLabel = NSTextField(labelWithString: "Custom user")
        let sshPortLabel = NSTextField(labelWithString: "SSH port")

        [localPortField, remotePortField, customHostField, customUserField, customSSHPortField].forEach {
            $0.bezelStyle = .roundedBezel
            $0.target = self
            $0.action = #selector(saveFromFields)
            $0.delegate = self
        }

        syncPortsButton.target = self
        syncPortsButton.action = #selector(syncChanged)
        launchAtLoginButton.target = self
        launchAtLoginButton.action = #selector(loginItemChanged)
        showRunningTargetButton.target = self
        showRunningTargetButton.action = #selector(showRunningTargetChanged)

        validationLabel.textColor = .systemRed
        validationLabel.lineBreakMode = .byWordWrapping
        validationLabel.maximumNumberOfLines = 2

        let form = NSGridView(views: [
            [localLabel, localPortField],
            [remoteLabel, remotePortField],
            [hostLabel, customHostField],
            [userLabel, customUserField],
            [sshPortLabel, customSSHPortField]
        ])
        form.column(at: 0).xPlacement = .trailing
        form.column(at: 1).width = 260
        form.rowSpacing = 10
        form.columnSpacing = 12

        let stack = NSStackView(views: [
            title,
            subtitle,
            form,
            syncPortsButton,
            launchAtLoginButton,
            showRunningTargetButton,
            validationLabel
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24)
        ])
    }

    private func loadValues() {
        let ports = store.portSettings
        localPortField.stringValue = String(ports.localPort)
        remotePortField.stringValue = String(ports.remotePort)
        syncPortsButton.state = ports.syncPorts ? .on : .off
        remotePortField.isEnabled = !ports.syncPorts

        let custom = store.customTarget
        customHostField.stringValue = custom.host
        customUserField.stringValue = custom.user
        customSSHPortField.stringValue = custom.port.map(String.init) ?? ""

        launchAtLoginButton.state = SMAppService.mainApp.status == .enabled ? .on : .off
        showRunningTargetButton.state = store.showRunningTargetInMenuBar ? .on : .off
        validationLabel.stringValue = ""
    }

    @objc private func syncChanged() {
        var ports = store.portSettings
        ports.syncPorts = syncPortsButton.state == .on
        if ports.syncPorts {
            ports.remotePort = ports.localPort
            remotePortField.stringValue = String(ports.remotePort)
        }
        store.portSettings = ports
        remotePortField.isEnabled = !ports.syncPorts
        delegate?.settingsDidChange()
    }

    @objc private func saveFromFields() {
        guard let localPort = Int(localPortField.stringValue), PortSettings.isValidPort(localPort) else {
            validationLabel.stringValue = "Local port must be between 1 and 65535."
            return
        }

        var ports = store.portSettings
        ports.setLocalPort(localPort)

        if !ports.syncPorts {
            guard let remotePort = Int(remotePortField.stringValue), PortSettings.isValidPort(remotePort) else {
                validationLabel.stringValue = "Remote port must be between 1 and 65535."
                return
            }
            ports.setRemotePort(remotePort)
        }

        let sshPort: Int?
        if customSSHPortField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sshPort = nil
        } else if let parsedPort = Int(customSSHPortField.stringValue), PortSettings.isValidPort(parsedPort) {
            sshPort = parsedPort
        } else {
            validationLabel.stringValue = "SSH port must be empty or between 1 and 65535."
            return
        }

        store.portSettings = ports
        store.customTarget = CustomSSHTarget(
            host: customHostField.stringValue,
            user: customUserField.stringValue,
            port: sshPort
        )
        remotePortField.stringValue = String(store.portSettings.remotePort)
        validationLabel.stringValue = ""
        delegate?.settingsDidChange()
    }

    @objc private func loginItemChanged() {
        do {
            if launchAtLoginButton.state == .on {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
            validationLabel.stringValue = ""
        } catch {
            launchAtLoginButton.state = SMAppService.mainApp.status == .enabled ? .on : .off
            validationLabel.stringValue = error.localizedDescription
        }
    }

    @objc private func showRunningTargetChanged() {
        store.showRunningTargetInMenuBar = showRunningTargetButton.state == .on
        delegate?.settingsDidChange()
    }
}
