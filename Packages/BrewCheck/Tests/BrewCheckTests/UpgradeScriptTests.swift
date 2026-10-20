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

    @Test func endsWithRecheckCall() {
        let script = UpgradeScript.content(brewPath: brew, greedy: true)
        #expect(script.hasSuffix("open -g \"thetap://recheck\"\n"))
    }
}