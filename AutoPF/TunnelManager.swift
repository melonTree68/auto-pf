import Foundation
import Darwin

final class TunnelManager: @unchecked Sendable {
    enum State: Equatable {
        case stopped
        case running(targetName: String, pid: Int32)
        case failed(message: String)
    }

    private(set) var state: State = .stopped {
        didSet { onStateChanged?(state) }
    }

    var onStateChanged: ((State) -> Void)?

    private var process: Process?
    private let sshPath: String

    init(sshPath: String = "/usr/bin/ssh") {
        self.sshPath = sshPath
    }

    func start(target: TunnelTarget, ports: PortSettings, forwardingMode: ForwardingMode) {
        guard target.isRunnable else {
            state = .failed(message: "SSH target is not configured.")
            return
        }

        stop()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: sshPath)
        process.arguments = SSHCommandBuilder.arguments(target: target, ports: ports, forwardingMode: forwardingMode)
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        process.terminationHandler = { [weak self, weak process] terminatedProcess in
            DispatchQueue.main.async {
                guard let self, self.process === process else { return }
                self.process = nil
                if terminatedProcess.terminationStatus == 0 {
                    self.state = .stopped
                } else {
                    self.state = .failed(message: "ssh exited with status \(terminatedProcess.terminationStatus).")
                }
            }
        }

        do {
            try process.run()
            self.process = process
            state = .running(targetName: target.displayName, pid: process.processIdentifier)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    func stop() {
        guard let runningProcess = process else {
            state = .stopped
            return
        }

        process = nil
        if runningProcess.isRunning {
            runningProcess.terminate()
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                if runningProcess.isRunning {
                    kill(runningProcess.processIdentifier, SIGKILL)
                }
            }
        }
        state = .stopped
    }

    func toggle(target: TunnelTarget, ports: PortSettings, forwardingMode: ForwardingMode) {
        switch state {
        case .running:
            stop()
        case .stopped, .failed:
            start(target: target, ports: ports, forwardingMode: forwardingMode)
        }
    }
}
