import XCTest
@testable import AutoPF

final class AutoPFTests: XCTestCase {
    func testShowRunningTargetInMenuBarDefaultsToFalseAndPersists() {
        let suiteName = "AutoPFTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var store = SettingsStore(defaults: defaults)
        XCTAssertFalse(store.showRunningTargetInMenuBar)

        store.showRunningTargetInMenuBar = true
        store = SettingsStore(defaults: defaults)

        XCTAssertTrue(store.showRunningTargetInMenuBar)
    }

    func testForwardingModeDefaultsToRemoteAndPersists() {
        let suiteName = "AutoPFTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var store = SettingsStore(defaults: defaults)
        XCTAssertEqual(store.forwardingMode, .remote)

        store.forwardingMode = .local
        store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.forwardingMode, .local)
    }

    func testSSHConfigParserSkipsPatternsAndKeepsConcreteAliases() {
        let config = """
        Host *
          ServerAliveInterval 60

        Host lab ubuntu !blocked test?
          HostName 127.0.0.1
          User zhijie
          Port 2222
        """

        let targets = SSHConfigParser.parse(contents: config)

        XCTAssertEqual(targets.map(\.alias), ["lab", "ubuntu"])
        XCTAssertEqual(targets.first?.hostName, "127.0.0.1")
        XCTAssertEqual(targets.first?.user, "zhijie")
        XCTAssertEqual(targets.first?.port, 2222)
    }

    func testSyncedPortsMirrorLocalPort() {
        var settings = PortSettings(localPort: 7890, remotePort: 9000, syncPorts: true)

        settings.setLocalPort(7000)
        settings.setRemotePort(8000)

        XCTAssertEqual(settings.localPort, 7000)
        XCTAssertEqual(settings.remotePort, 7000)
    }

    func testCustomTargetArguments() {
        let target = TunnelTarget.custom(CustomSSHTarget(host: "example.com", user: "deploy", port: 2222))
        let ports = PortSettings(localPort: 7890, remotePort: 9000, syncPorts: false)

        XCTAssertEqual(
            SSHCommandBuilder.arguments(target: target, ports: ports, forwardingMode: .remote),
            ["-N", "-R", "9000:127.0.0.1:7890", "-p", "2222", "deploy@example.com"]
        )
    }

    func testConfigTargetArguments() {
        let target = TunnelTarget.config(SSHConfigTarget(alias: "lab", hostName: nil, user: nil, port: nil))
        let ports = PortSettings(localPort: 7890, remotePort: 7890, syncPorts: true)

        XCTAssertEqual(
            SSHCommandBuilder.arguments(target: target, ports: ports, forwardingMode: .remote),
            ["-N", "-R", "7890:127.0.0.1:7890", "lab"]
        )
    }

    func testLocalForwardingArgumentsUseLocalListenPort() {
        let target = TunnelTarget.config(SSHConfigTarget(alias: "lab", hostName: nil, user: nil, port: nil))
        let ports = PortSettings(localPort: 7890, remotePort: 9000, syncPorts: false)

        XCTAssertEqual(
            SSHCommandBuilder.arguments(target: target, ports: ports, forwardingMode: .local),
            ["-N", "-L", "7890:127.0.0.1:9000", "lab"]
        )
    }
}
