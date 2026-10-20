import Foundation
import Testing
@testable import BrewCheck

@Suite struct BrewCheckerTests {
    private let gitJSON = """
    {"formulae":[{"name":"git","installed_versions":["2.46.0"],"current_version":"2.47.0","pinned":false}],"casks":[]}
    """

    /// A fixed environment, so the tests behave the same on every machine.
    private let testEnvironment = ["PATH": "/should/be/replaced", "HOME": "/tmp/test-home"]

    /// A locator that "finds" brew at /fake/bin/brew without touching the disk.
    private func makeChecker(_ runner: FakeRunner) -> BrewChecker {
        BrewChecker(
            runner: runner,
            locator: BrewLocator(path: "/fake/bin", isExecutable: { $0 == "/fake/bin/brew" }),
            baseEnvironment: testEnvironment)
    }

    private func caught(_ body: () async throws -> Void) async -> (any Error)? {
        do {
            try await body()
            return nil
        } catch {
            return error
        }
    }

    @Test func failedUpdateThrowsAndSkipsOutdated() async {
        let runner = FakeRunner(update: fakeResult(1, out: "some output", err: "boom"))
        let checker = makeChecker(runner)

        let error = await caught { _ = try await checker.outdated() }

        guard case .commandFailed(let command, let code, let output)? = error as? BrewCheckError else {
            Issue.record("wrong error: \(String(describing: error))")
            return
        }
        #expect(command == ["/fake/bin/brew", "update"])
        #expect(code == 1)
        #expect(output.contains("boom"))
        #expect(output.contains("some output"))
        #expect(await runner.calls.count == 1)
    }

    @Test func skipsUpdateWhenRunUpdateIsFalse() async throws {
        let runner = FakeRunner()
        _ = try await makeChecker(runner).outdated(runUpdate: false)

        let calls = await runner.calls
        #expect(calls.count == 1)
        #expect(calls[0].arguments.first == "outdated")
    }

    @Test func runsUpdateThenOutdatedByDefault() async throws {
        let runner = FakeRunner()
        _ = try await makeChecker(runner).outdated()

        let calls = await runner.calls
        #expect(calls.map { $0.arguments.first } == ["update", "outdated"])
        #expect(calls[0].executable.path == "/fake/bin/brew")
    }

    @Test func passesGreedyOnlyWhenRequested() async throws {
        let withGreedy = FakeRunner()
        _ = try await makeChecker(withGreedy).outdated(runUpdate: false, greedy: true)
        #expect(await withGreedy.calls[0].arguments == ["outdated", "--json=v2", "--greedy"])

        let withoutGreedy = FakeRunner()
        _ = try await makeChecker(withoutGreedy).outdated(runUpdate: false, greedy: false)
        #expect(await withoutGreedy.calls[0].arguments == ["outdated", "--json=v2"])
    }

    @Test func disablesAutoUpdateOnlyForOutdated() async throws {
        let runner = FakeRunner()
        _ = try await makeChecker(runner).outdated()

        let calls = await runner.calls
        #expect(calls[0].environment["HOMEBREW_NO_AUTO_UPDATE"] == nil)
        #expect(calls[1].environment["HOMEBREW_NO_AUTO_UPDATE"] == "1")
    }

    @Test func setsSafePathAndNoEnvHints() async throws {
        let runner = FakeRunner()
        _ = try await makeChecker(runner).outdated()

        for call in await runner.calls {
            #expect(call.environment["PATH"] == "/fake/bin:/usr/bin:/bin:/usr/sbin:/sbin")
            #expect(call.environment["HOMEBREW_NO_ENV_HINTS"] == "1")
        }
    }

    @Test func keepsBaseEnvironmentAndOverridesPath() async throws {
        let runner = FakeRunner()
        _ = try await makeChecker(runner).outdated()

        for call in await runner.calls {
            #expect(call.environment["HOME"] == "/tmp/test-home")
            #expect(call.environment["PATH"] != "/should/be/replaced")
        }
    }

    @Test func parsesOutdatedOutput() async throws {
        let runner = FakeRunner(outdated: fakeResult(out: gitJSON))
        let packages = try await makeChecker(runner).outdated(runUpdate: false)

        #expect(packages.map(\.name) == ["git"])
        #expect(packages[0].currentVersion == "2.47.0")
    }

    @Test func failedOutdatedThrowsCommandFailed() async {
        let runner = FakeRunner(outdated: fakeResult(1, err: "Error: something"))
        let checker = makeChecker(runner)

        let error = await caught { _ = try await checker.outdated(runUpdate: false) }

        guard case .commandFailed(let command, let code, let output)? = error as? BrewCheckError else {
            Issue.record("wrong error: \(String(describing: error))")
            return
        }
        #expect(command == ["/fake/bin/brew", "outdated", "--json=v2", "--greedy"])
        #expect(code == 1)
        #expect(output.contains("Error: something"))
    }

    @Test func invalidOutputThrowsInvalidJSON() async {
        let runner = FakeRunner(outdated: fakeResult(out: "not json"))
        let checker = makeChecker(runner)

        let error = await caught { _ = try await checker.outdated(runUpdate: false) }

        guard case .invalidJSON? = error as? BrewCheckError else {
            Issue.record("wrong error: \(String(describing: error))")
            return
        }
    }

    @Test func missingBrewThrowsBrewNotFound() async {
        let runner = FakeRunner()
        let checker = BrewChecker(
            runner: runner,
            locator: BrewLocator(path: "/fake/bin", isExecutable: { _ in false }),
            baseEnvironment: testEnvironment)

        let error = await caught { _ = try await checker.outdated() }

        guard case .brewNotFound(let searched)? = error as? BrewCheckError else {
            Issue.record("wrong error: \(String(describing: error))")
            return
        }
        #expect(searched.first == "/fake/bin/brew")
        #expect(await runner.calls.isEmpty)
    }
}