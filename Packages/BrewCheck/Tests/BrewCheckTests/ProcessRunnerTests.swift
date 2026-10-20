import Foundation
import Testing
@testable import BrewCheck

@Suite struct ProcessRunnerTests {
    let runner = ProcessRunner()
    let env = ["PATH": "/usr/bin:/bin"]

    private func text(_ data: Data) -> String {
        String(decoding: data, as: UTF8.self)
    }

    private func isTimedOut(_ error: any Error) -> Bool {
        if case .some(.timedOut) = error as? BrewCheckError { return true }
        return false
    }

    private func isCancelled(_ error: any Error) -> Bool {
        if case .some(.cancelled) = error as? BrewCheckError { return true }
        return false
    }

    @Test func capturesOutputAndExitCodeZero() async throws {
        let result = try await runner.run(
            URL(filePath: "/bin/echo"), arguments: ["hallo"],
            environment: env, timeout: .seconds(10))

        #expect(result.exitCode == 0)
        #expect(text(result.stdout) == "hallo\n")
    }

    @Test func reportsNonZeroExitCode() async throws {
        let result = try await runner.run(
            URL(filePath: "/bin/sh"), arguments: ["-c", "exit 3"],
            environment: env, timeout: .seconds(10))

        #expect(result.exitCode == 3)
    }

    @Test func keepsStdoutAndStderrApart() async throws {
        let result = try await runner.run(
            URL(filePath: "/bin/sh"), arguments: ["-c", "echo out; echo err >&2"],
            environment: env, timeout: .seconds(10))

        #expect(text(result.stdout) == "out\n")
        #expect(text(result.stderr) == "err\n")
    }

    @Test func handlesLargeOutputWithoutHanging() async throws {
        let result = try await runner.run(
            URL(filePath: "/bin/sh"), arguments: ["-c", "head -c 5000000 /dev/zero"],
            environment: env, timeout: .seconds(30))

        #expect(result.exitCode == 0)
        #expect(result.stdout.count == 5_000_000)
    }

    @Test func timesOutHangingCommand() async {
        let start = ContinuousClock.now

        do {
            _ = try await runner.run(
                URL(filePath: "/bin/sleep"), arguments: ["30"],
                environment: env, timeout: .seconds(1))
            Issue.record("expected timedOut, but the command finished")
        } catch {
            #expect(isTimedOut(error), "wrong error: \(error)")
        }

        #expect(ContinuousClock.now - start < .seconds(10))
    }

    @Test func cancelsWhenTaskIsCancelled() async throws {
        let runner = self.runner
        let env = self.env

        let task = Task {
            try await runner.run(
                URL(filePath: "/bin/sleep"), arguments: ["30"],
                environment: env, timeout: .seconds(60))
        }

        try await Task.sleep(for: .milliseconds(500))
        task.cancel()

        switch await task.result {
        case .success:
            Issue.record("expected cancelled, but the command finished")
        case .failure(let error):
            #expect(isCancelled(error), "wrong error: \(error)")
        }
    }
}