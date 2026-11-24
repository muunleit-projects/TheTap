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

    @Test func trapsAreSetBeforeUpgradeRuns() throws {
        let script = UpgradeScript.content(brewPath: brew, greedy: true)
        let exitTrap = try #require(script.range(of: "trap recheck EXIT"))
        let intTrap = try #require(script.range(of: "trap 'recheck; exit 130' INT"))
        let upgrade = try #require(script.range(of: "upgrade --greedy --no-ask"))
        #expect(exitTrap.lowerBound < upgrade.lowerBound)
        #expect(intTrap.lowerBound < upgrade.lowerBound)
    }

    @Test func recheckIsSentOnlyOnce() {
        let script = UpgradeScript.content(brewPath: brew, greedy: true)
        #expect(script.components(separatedBy: "open -g").count == 2)
        #expect(script.contains("if (( ! rechecked )); then"))
    }

    @Test func interruptTrapExitsWithCode130() {
        let script = UpgradeScript.content(brewPath: brew, greedy: true)
        #expect(script.contains("exit 130"))
    }

    @Test func recheckComesBeforeWaitingForKey() throws {
        let script = UpgradeScript.content(brewPath: brew, greedy: true)
        let recheck = try #require(script.range(of: "\nrecheck\n"))
        let wait = try #require(script.range(of: "read -k 1"))
        #expect(recheck.lowerBound < wait.lowerBound)
    }

    @Test func waitsForKeyAtTheEnd() {
        let script = UpgradeScript.content(brewPath: brew, greedy: true)
        #expect(script.hasSuffix("beliebige Taste drücken …\"\n"))
    }
}
