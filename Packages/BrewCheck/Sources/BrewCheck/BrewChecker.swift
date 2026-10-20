import Foundation

/// Runs `brew update` and `brew outdated` and returns the outdated packages.
/// An actor, so two checks never run at the same time.
public actor BrewChecker {
    private let runner: any CommandRunner
    private let locator: BrewLocator
    private let updateTimeout: Duration
    private let outdatedTimeout: Duration

    public init(
        runner: any CommandRunner = ProcessRunner(),
        locator: BrewLocator = BrewLocator(),
        updateTimeout: Duration = .seconds(600),
        outdatedTimeout: Duration = .seconds(120)
    ) {
        self.runner = runner
        self.locator = locator
        self.updateTimeout = updateTimeout
        self.outdatedTimeout = outdatedTimeout
    }

    public func outdated(runUpdate: Bool = true, greedy: Bool = true) async throws -> [OutdatedPackage] {
        let brew = try locator.locate()
        let baseEnvironment = Self.environment(brewDirectory: brew.deletingLastPathComponent().path)

        if runUpdate {
            let arguments = ["update"]
            let result = try await runner.run(
                brew, arguments: arguments,
                environment: baseEnvironment, timeout: updateTimeout)
            guard result.exitCode == 0 else {
                throw BrewCheckError.commandFailed(
                    command: [brew.path] + arguments,
                    exitCode: result.exitCode,
                    output: Self.outputText(result))
            }
        }

        var arguments = ["outdated", "--json=v2"]
        if greedy { arguments.append("--greedy") }

        // `update` ran right before (or the caller does not want it).
        var environment = baseEnvironment
        environment["HOMEBREW_NO_AUTO_UPDATE"] = "1"

        let result = try await runner.run(
            brew, arguments: arguments,
            environment: environment, timeout: outdatedTimeout)
        guard result.exitCode == 0 else {
            throw BrewCheckError.commandFailed(
                command: [brew.path] + arguments,
                exitCode: result.exitCode,
                output: Self.outputText(result))
        }

        // Only stdout is JSON; stderr holds warnings and is ignored here.
        return try OutdatedParser.parse(result.stdout)
    }

    /// The process environment with a safe PATH that starts with brew's directory.
    static func environment(brewDirectory: String) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "\(brewDirectory):/usr/bin:/bin:/usr/sbin:/sbin"
        environment["HOMEBREW_NO_ENV_HINTS"] = "1"
        return environment
    }

    /// stdout and stderr as one text, limited to the last 200 lines.
    static func outputText(_ result: CommandResult) -> String {
        let parts = [result.stdout, result.stderr]
            .map { String(decoding: $0, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let lines = parts.joined(separator: "\n").split(separator: "\n", omittingEmptySubsequences: false)
        return lines.suffix(200).joined(separator: "\n")
    }
}