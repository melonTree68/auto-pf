import Foundation

final class SettingsStore {
    private enum Key {
        static let localPort = "localPort"
        static let remotePort = "remotePort"
        static let syncPorts = "syncPorts"
        static let customHost = "customHost"
        static let customUser = "customUser"
        static let customSSHPort = "customSSHPort"
        static let selectedTargetAlias = "selectedTargetAlias"
        static let selectedTargetKind = "selectedTargetKind"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Key.localPort) == nil {
            defaults.set(7890, forKey: Key.localPort)
            defaults.set(7890, forKey: Key.remotePort)
            defaults.set(true, forKey: Key.syncPorts)
            defaults.set("custom", forKey: Key.selectedTargetKind)
        }
    }

    var portSettings: PortSettings {
        get {
            PortSettings(
                localPort: defaults.integer(forKey: Key.localPort),
                remotePort: defaults.integer(forKey: Key.remotePort),
                syncPorts: defaults.bool(forKey: Key.syncPorts)
            )
        }
        set {
            defaults.set(newValue.localPort, forKey: Key.localPort)
            defaults.set(newValue.remotePort, forKey: Key.remotePort)
            defaults.set(newValue.syncPorts, forKey: Key.syncPorts)
        }
    }

    var customTarget: CustomSSHTarget {
        get {
            let port = defaults.integer(forKey: Key.customSSHPort)
            return CustomSSHTarget(
                host: defaults.string(forKey: Key.customHost) ?? "",
                user: defaults.string(forKey: Key.customUser) ?? "",
                port: port == 0 ? nil : port
            )
        }
        set {
            defaults.set(newValue.host, forKey: Key.customHost)
            defaults.set(newValue.user, forKey: Key.customUser)
            defaults.set(newValue.port ?? 0, forKey: Key.customSSHPort)
        }
    }

    var selectedTargetKind: String {
        get { defaults.string(forKey: Key.selectedTargetKind) ?? "custom" }
        set { defaults.set(newValue, forKey: Key.selectedTargetKind) }
    }

    var selectedTargetAlias: String? {
        get { defaults.string(forKey: Key.selectedTargetAlias) }
        set { defaults.set(newValue, forKey: Key.selectedTargetAlias) }
    }
}
