import Testing

@testable import BrewCheck

@Suite("UpgradeScript")
struct UpgradeScriptTests {
    private let brew = "/opt/homebrew/bin/brew"

    @Test func startsWithShebang() {
        let script = UpgradeScript.content(brewPath: brew, greedy: true)
        #expect(script.hasPrefix("#!/bin/zsh\n"))
    }

    @Test func greedyAddsFlag() {
        let script = UpgradeScript.content(brewPath: brew, greedy: true)
        #expect(script.contains("upgrade --greedy --no-ask"))
    }

    @Test func nonGreedyOmitsFlag() {
        let script = UpgradeScript.content(brewPath: brew, greedy: false)
        #expect(script.contains("upgrade --no-ask"))
        #expect(!script.contains("--greedy"))
    }

    @Test func quotesPathWithSpaceAndApostrophe() {
        let quoted = UpgradeScript.shellQuoted("/Users/o'brien/my brew")
        #expect(quoted == #"'/Users/o'\''brien/my brew'"#)
    }

    @Test func recheckComesBeforeWaitingForKey() throws {
        let script = UpgradeScript.content(brewPath: brew, greedy: true)
        let recheck = try #require(script.range(of: "open -g \"thetap://recheck\""))
        let wait = try #require(script.range(of: "read -k 1"))
        #expect(recheck.lowerBound < wait.lowerBound)
    }

    @Test func waitsForKeyAtTheEnd() {
        let script = UpgradeScript.content(brewPath: brew, greedy: true)
        #expect(script.hasSuffix("beliebige Taste drücken …\"\n"))
    }
}