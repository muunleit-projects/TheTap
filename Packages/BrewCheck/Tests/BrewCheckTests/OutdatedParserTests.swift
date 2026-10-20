import Foundation
import Testing
@testable import BrewCheck

@Suite struct OutdatedParserTests {
    private func fixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
            ?? Bundle.module.url(forResource: name, withExtension: "json")
        let found = try #require(url, "fixture \(name).json not found")
        return try Data(contentsOf: found)
    }

    private func expectInvalidJSON(_ data: Data) {
        do {
            _ = try OutdatedParser.parse(data)
            Issue.record("expected invalidJSON, but parsing succeeded")
        } catch BrewCheckError.invalidJSON {
            // expected
        } catch {
            Issue.record("wrong error: \(error)")
        }
    }

    @Test func readsRealOutput() throws {
        let pkgs = try OutdatedParser.parse(fixture("real"))

        #expect(pkgs.count == 1)
        #expect(pkgs[0].name == "losslesscut")
        #expect(pkgs[0].kind == .cask)
        #expect(pkgs[0].installedVersions == ["3.69.0"])
        #expect(pkgs[0].currentVersion == "3.70.1")
        #expect(pkgs[0].pinned == false)
    }

    @Test func emptyListsGiveEmptyResult() throws {
        #expect(try OutdatedParser.parse(fixture("empty")).isEmpty)
    }

    @Test func readsFormulaeOnly() throws {
        let pkgs = try OutdatedParser.parse(fixture("formulae-only"))

        #expect(pkgs.map(\.name) == ["git"])
        #expect(pkgs[0].kind == .formula)
    }

    @Test func readsCasksOnly() throws {
        let pkgs = try OutdatedParser.parse(fixture("casks-only"))

        #expect(pkgs.map(\.name) == ["firefox"])
        #expect(pkgs[0].kind == .cask)
    }

    @Test func sortsFormulaeBeforeCasksAndByName() throws {
        let pkgs = try OutdatedParser.parse(fixture("pinned"))

        #expect(pkgs.map(\.name) == ["git", "node", "zsh", "firefox", "visual-studio-code"])
        #expect(pkgs.map(\.kind) == [.formula, .formula, .formula, .cask, .cask])
    }

    @Test func readsPinnedFlagAndMultipleVersions() throws {
        let pkgs = try OutdatedParser.parse(fixture("pinned"))
        let git = try #require(pkgs.first { $0.name == "git" })
        let node = try #require(pkgs.first { $0.name == "node" })
        let code = try #require(pkgs.first { $0.name == "visual-studio-code" })

        #expect(git.installedVersions == ["2.44.0", "2.44.1"])
        #expect(git.pinned == false)
        #expect(node.pinned == true)
        #expect(code.pinned == false) // "pinned" missing in the JSON
    }

    @Test func acceptsSingleStringAsInstalledVersions() throws {
        let pkgs = try OutdatedParser.parse(fixture("pinned"))
        let firefox = try #require(pkgs.first { $0.name == "firefox" })

        #expect(firefox.installedVersions == ["125.0"])
    }

    @Test func ignoresUnknownFields() throws {
        let pkgs = try OutdatedParser.parse(fixture("extra-fields"))

        #expect(pkgs.map(\.name) == ["git"])
    }

    @Test func missingKeysCountAsEmpty() throws {
        #expect(try OutdatedParser.parse(Data("{}".utf8)).isEmpty)
    }

    @Test func rejectsBrokenJSON() throws {
        expectInvalidJSON(try fixture("broken"))
    }

    @Test func rejectsBlankAndEmptyInput() throws {
        expectInvalidJSON(try fixture("blank"))
        expectInvalidJSON(Data())
        expectInvalidJSON(Data("  \n".utf8))
    }

    @Test func errorKeepsOnlyFirst500Characters() {
        let data = Data(String(repeating: "x", count: 600).utf8)

        do {
            _ = try OutdatedParser.parse(data)
            Issue.record("expected invalidJSON")
        } catch BrewCheckError.invalidJSON(let text) {
            #expect(text.count == 500)
        } catch {
            Issue.record("wrong error: \(error)")
        }
    }
}