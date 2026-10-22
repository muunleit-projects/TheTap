import Foundation
import Testing
@testable import BrewCheck

@Suite struct LogDetailsTests {
    @Test func commandFailedNamesCommandExitCodeAndOutput() {
        let error = BrewCheckError.commandFailed(
            command: ["/opt/homebrew/bin/brew", "update"], exitCode: 1, output: "Could not resolve host")
        let details = error.logDetails
        #expect(details.hasPrefix("Command failed (exit code 1): /opt/homebrew/bin/brew update"))
        #expect(details.hasSuffix("Could not resolve host"))
    }

    @Test func commandFailedKeepsOnlyTheLastTwoHundredLines() {
        let output = (1...250).map { "zeile-\($0)" }.joined(separator: "\n") + "\n"
        let error = BrewCheckError.commandFailed(command: ["brew"], exitCode: 1, output: output)
        let lines = error.logDetails.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.count == 201)
        #expect(lines[1] == "zeile-51")
        #expect(lines.last == "zeile-250")
    }

    @Test func brewNotFoundListsSearchedPaths() {
        let error = BrewCheckError.brewNotFound(searched: ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"])
        #expect(error.logDetails.contains("/opt/homebrew/bin/brew, /usr/local/bin/brew"))
    }

    @Test func timedOutNamesSecondsAndCommand() {
        let error = BrewCheckError.timedOut(command: ["brew", "update"], after: .seconds(600))
        #expect(error.logDetails == "Command timed out after 600 s: brew update")
    }

    @Test func invalidJSONContainsTheOutput() {
        let error = BrewCheckError.invalidJSON("{ kaputt")
        #expect(error.logDetails.hasSuffix("{ kaputt"))
    }
}