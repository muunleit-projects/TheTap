import Foundation

/// Parses the output of `brew outdated --json=v2`.
public enum OutdatedParser {
    /// Returns formulae first, then casks, each sorted by name.
    /// Missing lists count as empty; unknown fields are ignored.
    public static func parse(_ data: Data) throws -> [OutdatedPackage] {
        let text = String(decoding: data, as: UTF8.self)

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BrewCheckError.invalidJSON("")
        }

        let raw: RawOutput
        do {
            raw = try JSONDecoder().decode(RawOutput.self, from: data)
        } catch {
            throw BrewCheckError.invalidJSON(String(text.prefix(500)))
        }

        return convert(raw.formulae ?? [], kind: .formula)
            + convert(raw.casks ?? [], kind: .cask)
    }

    private static func convert(_ list: [RawPackage], kind: PackageKind) -> [OutdatedPackage] {
        list
            .map {
                OutdatedPackage(
                    name: $0.name,
                    kind: kind,
                    installedVersions: $0.installedVersions,
                    currentVersion: $0.currentVersion,
                    pinned: $0.pinned
                )
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

private struct RawOutput: Decodable {
    let formulae: [RawPackage]?
    let casks: [RawPackage]?
}

private struct RawPackage: Decodable {
    let name: String
    let installedVersions: [String]
    let currentVersion: String
    let pinned: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case installedVersions = "installed_versions"
        case currentVersion = "current_version"
        case pinned
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)

        // A list (current brew) or a single string (some older casks).
        if let list = try? c.decode([String].self, forKey: .installedVersions) {
            installedVersions = list
        } else if let single = try? c.decode(String.self, forKey: .installedVersions) {
            installedVersions = [single]
        } else {
            installedVersions = []
        }

        currentVersion = try c.decodeIfPresent(String.self, forKey: .currentVersion) ?? ""
        pinned = try c.decodeIfPresent(Bool.self, forKey: .pinned) ?? false
    }
}