import BrewCheck
import Foundation

/// Turns the package list into text for the terminal.
enum OutputFormatter {
    static func table(_ packages: [OutdatedPackage]) -> String {
        if packages.isEmpty { return "Alles aktuell." }

        let width = (packages.map(\.name.count).max() ?? 0) + 2
        let sections: [(title: String, kind: PackageKind)] = [
            ("Formulae", .formula),
            ("Casks", .cask),
        ]

        var lines: [String] = []
        for section in sections {
            let group = packages.filter { $0.kind == section.kind }
            guard !group.isEmpty else { continue }
            if !lines.isEmpty { lines.append("") }
            lines.append(section.title)
            for package in group {
                let name = package.name.padding(toLength: width, withPad: " ", startingAt: 0)
                let installed = package.installedVersions.joined(separator: ", ")
                let suffix = package.pinned ? " (angepinnt)" : ""
                lines.append("  \(name)\(installed) → \(package.currentVersion)\(suffix)")
            }
        }
        return lines.joined(separator: "\n")
    }

    static func json(_ packages: [OutdatedPackage]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return String(decoding: try encoder.encode(packages), as: UTF8.self)
    }
}