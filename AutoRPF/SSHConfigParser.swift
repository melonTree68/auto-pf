import Foundation

enum SSHConfigParser {
    static func parse(contents: String) -> [SSHConfigTarget] {
        var targets: [SSHConfigTarget] = []
        var currentAliases: [String] = []
        var currentHostName: String?
        var currentUser: String?
        var currentPort: Int?

        func flush() {
            for alias in currentAliases where isConcreteHostAlias(alias) {
                targets.append(
                    SSHConfigTarget(
                        alias: alias,
                        hostName: currentHostName,
                        user: currentUser,
                        port: currentPort
                    )
                )
            }

            currentAliases = []
            currentHostName = nil
            currentUser = nil
            currentPort = nil
        }

        for rawLine in contents.components(separatedBy: .newlines) {
            let trimmed = stripComment(from: rawLine).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let parts = trimmed.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
            guard let keyword = parts.first?.lowercased() else { continue }

            if keyword == "host" {
                flush()
                currentAliases = Array(parts.dropFirst())
                continue
            }

            guard !currentAliases.isEmpty, parts.count >= 2 else { continue }
            let value = parts.dropFirst().joined(separator: " ")

            switch keyword {
            case "hostname":
                currentHostName = value
            case "user":
                currentUser = value
            case "port":
                currentPort = Int(value)
            default:
                break
            }
        }

        flush()

        var seen = Set<String>()
        return targets.filter { target in
            seen.insert(target.alias).inserted
        }
    }

    static func parseFile(at url: URL) -> [SSHConfigTarget] {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return parse(contents: contents)
    }

    private static func stripComment(from line: String) -> String {
        var result = ""
        var isEscaped = false

        for character in line {
            if character == "#" && !isEscaped {
                break
            }

            result.append(character)
            isEscaped = character == "\\"
        }

        return result
    }

    private static func isConcreteHostAlias(_ alias: String) -> Bool {
        guard !alias.hasPrefix("!") else { return false }
        return !alias.contains("*") && !alias.contains("?")
    }
}
