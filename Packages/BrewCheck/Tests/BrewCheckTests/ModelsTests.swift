import Testing
import BrewCheck

@Test func outdatedPackageKeepsItsValues() {
    let package = OutdatedPackage(
        name: "git",
        kind: .formula,
        installedVersions: ["2.46.0"],
        currentVersion: "2.47.0",
        pinned: false
    )

    #expect(package.name == "git")
    #expect(package.kind == .formula)
    #expect(package.installedVersions == ["2.46.0"])
    #expect(!package.pinned)
}