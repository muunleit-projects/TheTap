import Foundation
@testable import BrewCheck

/// Builds a `CommandResult` from text.
func fakeResult(_ exitCode: Int32 = 0, out: String = "", err: String = "") -> CommandResult {
    CommandResult(exitCode: exitCode, stdout: Data(out.utf8), stderr: Data(err.utf8))
}

/// A `CommandRunner` that never starts a process. It answers by the first
/// argument (`update` or `outdated`) and records every call.
actor FakeRunner: CommandRunner {
    struct Call: Sendable {
        let executable: URL
        let arguments: [String]
        let environment: [String: String]
    }

    private(set) var calls: [Call] = []
    private let update: CommandResult
    private let outdated: CommandResult

    init(
        update: CommandResult = fakeResult(),
        outdated: CommandResult = fakeResult(out: #"{"formulae":[],"casks":[]}"#)
    ) {
        self.update = update
        self.outdated = outdated
    }

    func run(
        _ executable: URL,
        arguments: [String],
        environment: [String: String],
        timeout: Duration
    ) async throws -> CommandResult {
        calls.append(Call(executable: executable, arguments: arguments, environment: environment))
        return arguments.first == "update" ? update : outdated
    }
}