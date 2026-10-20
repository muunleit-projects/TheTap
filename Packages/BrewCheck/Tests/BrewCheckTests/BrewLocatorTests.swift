import Foundation
import Testing
import BrewCheck

private func makeLocator(path: String, existing: Set<String>) -> BrewLocator {
    BrewLocator(path: path, isExecutable: { existing.contains($0) })
}

@Test func findsBrewInPath() throws {
    let locator = makeLocator(
        path: "/custom/bin:/usr/bin",
        existing: ["/custom/bin/brew", "/opt/homebrew/bin/brew"]
    )

    #expect(try locator.locate().path == "/custom/bin/brew")
}

@Test func fallsBackToAppleSiliconLocation() throws {
    let locator = makeLocator(
        path: "/usr/bin",
        existing: ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
    )

    #expect(try locator.locate().path == "/opt/homebrew/bin/brew")
}

@Test func fallsBackToIntelLocation() throws {
    let locator = makeLocator(path: "", existing: ["/usr/local/bin/brew"])

    #expect(try locator.locate().path == "/usr/local/bin/brew")
}

@Test func reportsAllSearchedPathsWhenNothingIsFound() {
    let locator = makeLocator(path: "/a:/b", existing: [])

    let error = #expect(throws: BrewCheckError.self) {
        try locator.locate()
    }

    guard case .brewNotFound(let searched)? = error else {
        Issue.record("expected brewNotFound, got \(String(describing: error))")
        return
    }

    #expect(searched == [
        "/a/brew", "/b/brew", "/opt/homebrew/bin/brew", "/usr/local/bin/brew",
    ])
}

@Test func doesNotListDuplicatePaths() {
    let locator = makeLocator(path: "/opt/homebrew/bin:/usr/bin", existing: [])

    let error = #expect(throws: BrewCheckError.self) {
        try locator.locate()
    }

    guard case .brewNotFound(let searched)? = error else {
        Issue.record("expected brewNotFound")
        return
    }

    #expect(searched.filter { $0 == "/opt/homebrew/bin/brew" }.count == 1)
}