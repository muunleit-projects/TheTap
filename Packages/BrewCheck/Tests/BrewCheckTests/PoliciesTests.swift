import Foundation
import Testing
@testable import BrewCheck

@Suite struct PoliciesTests {
    private func pkg(
        _ name: String,
        _ kind: PackageKind = .formula,
        version: String = "2.0",
        pinned: Bool = false
    ) -> OutdatedPackage {
        OutdatedPackage(
            name: name, kind: kind, installedVersions: ["1.0"],
            currentVersion: version, pinned: pinned)
    }

    // MARK: isCheckDue

    private let now = Date(timeIntervalSince1970: 1_000_000)
    private let sixHours: TimeInterval = 6 * 3600

    @Test func checkIsDueWithoutPreviousSuccess() {
        #expect(Policies.isCheckDue(lastSuccess: nil, interval: sixHours, now: now))
    }

    @Test func checkIsNotDueBeforeIntervalPassed() {
        let last = now.addingTimeInterval(-(sixHours - 60))
        #expect(!Policies.isCheckDue(lastSuccess: last, interval: sixHours, now: now))
    }

    @Test func checkIsDueExactlyAtInterval() {
        let last = now.addingTimeInterval(-sixHours)
        #expect(Policies.isCheckDue(lastSuccess: last, interval: sixHours, now: now))
    }

    @Test func checkIsDueAfterIntervalPassed() {
        let last = now.addingTimeInterval(-(sixHours * 3))
        #expect(Policies.isCheckDue(lastSuccess: last, interval: sixHours, now: now))
    }

    @Test func checkIsDueWhenLastSuccessIsInTheFuture() {
        let last = now.addingTimeInterval(3600)
        #expect(Policies.isCheckDue(lastSuccess: last, interval: sixHours, now: now))
    }

    // MARK: showsFailure

    @Test func thresholdIsThreeFailures() {
        #expect(Policies.failuresBeforeError == 3)
    }

    @Test func manualCheckShowsFailureImmediately() {
        #expect(Policies.showsFailure(consecutiveFailures: 1, manual: true))
    }

    @Test func automaticCheckStaysSilentBelowThreshold() {
        #expect(!Policies.showsFailure(consecutiveFailures: 1, manual: false))
        #expect(!Policies.showsFailure(consecutiveFailures: 2, manual: false))
    }

    @Test func automaticCheckShowsFailureAtThreshold() {
        #expect(Policies.showsFailure(consecutiveFailures: 3, manual: false))
    }

    @Test func automaticCheckShowsFailureAboveThreshold() {
        #expect(Policies.showsFailure(consecutiveFailures: 4, manual: false))
    }

    // MARK: newlyOutdated

    @Test func everythingIsNewWhenNothingWasNotified() {
        let result = Policies.newlyOutdated(
            current: [pkg("git"), pkg("firefox", .cask)], alreadyNotified: [])
        #expect(result.map(\.name) == ["git", "firefox"])
    }

    @Test func skipsAlreadyNotifiedPackages() {
        let git = pkg("git")
        let result = Policies.newlyOutdated(
            current: [git, pkg("zsh")], alreadyNotified: [git.key])
        #expect(result.map(\.name) == ["zsh"])
    }

    @Test func newVersionOfNotifiedPackageIsNew() {
        let old = pkg("git", version: "2.47.0")
        let result = Policies.newlyOutdated(
            current: [pkg("git", version: "2.48.0")], alreadyNotified: [old.key])
        #expect(result.map(\.name) == ["git"])
    }

    @Test func neverReportsPinnedPackages() {
        let result = Policies.newlyOutdated(
            current: [pkg("node", pinned: true), pkg("git")], alreadyNotified: [])
        #expect(result.map(\.name) == ["git"])
    }

    @Test func formulaAndCaskWithSameNameAreDifferent() {
        let formula = pkg("foo", .formula)
        let result = Policies.newlyOutdated(
            current: [formula, pkg("foo", .cask)], alreadyNotified: [formula.key])
        #expect(result.map(\.kind) == [.cask])
    }

    // MARK: pruneNotified

    @Test func pruneRemovesPackagesThatAreNoLongerOutdated() {
        let git = pkg("git")
        let zsh = pkg("zsh")
        let result = Policies.pruneNotified([git.key, zsh.key], current: [zsh])
        #expect(result == [zsh.key])
    }

    @Test func pruneKeepsPackagesThatAreStillOutdated() {
        let git = pkg("git")
        let result = Policies.pruneNotified([git.key], current: [git])
        #expect(result == [git.key])
    }

    @Test func pruneRemovesEntryWhenVersionChanged() {
        let old = pkg("git", version: "2.47.0")
        let result = Policies.pruneNotified([old.key], current: [pkg("git", version: "2.48.0")])
        #expect(result.isEmpty)
    }

    // MARK: badgeCount

    @Test func badgeCountIgnoresPinnedPackages() {
        let count = Policies.badgeCount([
            pkg("git"), pkg("node", pinned: true), pkg("firefox", .cask),
        ])
        #expect(count == 2)
    }

    @Test func badgeCountIsZeroForEmptyList() {
        #expect(Policies.badgeCount([]) == 0)
    }

    // MARK: notificationText

    @Test func titleForOneUpdateIsSingular() {
        let text = Policies.notificationText(newPackages: [pkg("git")], badgeCount: 1)
        #expect(text.title == "1 Homebrew-Update verfügbar")
    }

    @Test func titleForSeveralUpdatesIsPlural() {
        let text = Policies.notificationText(
            newPackages: [pkg("git"), pkg("node")], badgeCount: 2)
        #expect(text.title == "2 Homebrew-Updates verfügbar")
    }

    @Test func titleUsesBadgeCountNotNumberOfNewPackages() {
        let text = Policies.notificationText(newPackages: [pkg("git")], badgeCount: 3)
        #expect(text.title == "3 Homebrew-Updates verfügbar")
    }

    @Test func bodyForOnePackage() {
        let text = Policies.notificationText(newPackages: [pkg("git")], badgeCount: 1)
        #expect(text.body == "git")
    }

    @Test func bodyForTwoPackages() {
        let text = Policies.notificationText(
            newPackages: [pkg("git"), pkg("node")], badgeCount: 2)
        #expect(text.body == "git und node")
    }

    @Test func bodyForThreePackages() {
        let text = Policies.notificationText(
            newPackages: [pkg("git"), pkg("node"), pkg("wget")], badgeCount: 3)
        #expect(text.body == "git, node und wget")
    }

    @Test func bodyForFourPackagesSaysOneMore() {
        let text = Policies.notificationText(
            newPackages: [pkg("git"), pkg("node"), pkg("wget"), pkg("zsh")], badgeCount: 4)
        #expect(text.body == "git, node, wget und 1 weiteres")
    }

    @Test func bodyForFivePackagesSaysTwoMore() {
        let text = Policies.notificationText(
            newPackages: [pkg("git"), pkg("node"), pkg("wget"), pkg("zsh"), pkg("jq")],
            badgeCount: 5)
        #expect(text.body == "git, node, wget und 2 weitere")
    }

    @Test func bodyIsEmptyWithoutNewPackages() {
        let text = Policies.notificationText(newPackages: [], badgeCount: 2)
        #expect(text.body.isEmpty)
    }
}