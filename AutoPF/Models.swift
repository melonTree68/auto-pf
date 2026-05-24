import Foundation

struct SSHConfigTarget: Equatable {
    let alias: String
    let hostName: String?
    let user: String?
    let port: Int?
}

struct CustomSSHTarget: Equatable {
    var host: String
    var user: String
    var port: Int?

    var displayName: String {
        let prefix = user.trimmingCharacters(in: .whitespacesAndNewlines)
        let hostName = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if prefix.isEmpty {
            return hostName
        }
        return "\(prefix)@\(hostName)"
    }
}

enum TunnelTarget: Equatable {
    case config(SSHConfigTarget)
    case custom(CustomSSHTarget)

    var displayName: String {
        switch self {
        case .config(let target):
            return target.alias
        case .custom(let target):
            return target.displayName.isEmpty ? "Custom Target" : target.displayName
        }
    }

    var isRunnable: Bool {
        switch self {
        case .config:
            return true
        case .custom(let target):
            return !target.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

struct PortSettings: Equatable {
    var localPort: Int
    var remotePort: Int
    var syncPorts: Bool

    init(localPort: Int = 7890, remotePort: Int = 7890, syncPorts: Bool = true) {
        self.localPort = localPort
        self.remotePort = syncPorts ? localPort : remotePort
        self.syncPorts = syncPorts
    }

    mutating func setLocalPort(_ port: Int) {
        localPort = port
        if syncPorts {
            remotePort = port
        }
    }

    mutating func setRemotePort(_ port: Int) {
        guard !syncPorts else { return }
        remotePort = port
    }

    static func isValidPort(_ value: Int) -> Bool {
        (1...65535).contains(value)
    }
}

enum ForwardingMode: String, Equatable {
    case remote = "-R"
    case local = "-L"
}

enum SSHCommandBuilder {
    static func arguments(target: TunnelTarget, ports: PortSettings, forwardingMode: ForwardingMode) -> [String] {
        let forwarding: String
        switch forwardingMode {
        case .remote:
            forwarding = "127.0.0.1:\(ports.remotePort):127.0.0.1:\(ports.localPort)"
        case .local:
            forwarding = "127.0.0.1:\(ports.localPort):127.0.0.1:\(ports.remotePort)"
        }
        var arguments = ["-N", forwardingMode.rawValue, forwarding]

        switch target {
        case .config(let config):
            arguments.append(config.alias)
        case .custom(let custom):
            if let port = custom.port {
                arguments.append(contentsOf: ["-p", String(port)])
            }

            let host = custom.host.trimmingCharacters(in: .whitespacesAndNewlines)
            let user = custom.user.trimmingCharacters(in: .whitespacesAndNewlines)
            arguments.append(user.isEmpty ? host : "\(user)@\(host)")
        }

        return arguments
    }
}
