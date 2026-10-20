import Foundation

/// Runs commands with `Foundation.Process`.
///
/// - stdout and stderr are read in parallel while the command runs.
/// - On timeout: SIGTERM, after 5 seconds SIGKILL, then `timedOut`.
/// - On task cancellation: the same stop sequence, then `cancelled`.
/// - After the process ended, waits at most 5 seconds for the pipes to close.
public struct ProcessRunner: CommandRunner {
    public init() {}

    public func run(
        _ executable: URL,
        arguments: [String],
        environment: [String: String],
        timeout: Duration
    ) async throws -> CommandResult {
        if Task.isCancelled { throw BrewCheckError.cancelled }

        let command = [executable.path] + arguments
        let box = ProcessBox()
        let process = box.process
        process.executableURL = executable
        process.arguments = arguments
        process.environment = environment
        process.standardInput = FileHandle.nullDevice

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        let out = PipeReader(outPipe.fileHandleForReading)
        let err = PipeReader(errPipe.fileHandleForReading)

        // The stream buffers the value, so it does not matter whether the
        // process ends before or after we start waiting.
        let (exitStream, exitContinuation) = AsyncStream<Int32>.makeStream()
        process.terminationHandler = { finished in
            exitContinuation.yield(finished.terminationStatus)
            exitContinuation.finish()
        }

        do {
            try process.run()
        } catch {
            out.stop()
            err.stop()
            throw BrewCheckError.commandFailed(
                command: command,
                exitCode: -1,
                output: "Could not start: \(error.localizedDescription)"
            )
        }

        let timedOut = Flag()
        let cancelled = Flag()

        let status: Int32 = await withTaskCancellationHandler {
            await withTaskGroup(of: Int32?.self) { group in
                group.addTask {
                    for await code in exitStream { return code }
                    return nil
                }
                group.addTask {
                    do { try await Task.sleep(for: timeout) } catch { return nil }
                    timedOut.set()
                    box.terminateThenKill()
                    return nil
                }
                for await result in group {
                    if let code = result {
                        group.cancelAll()
                        return code
                    }
                }
                return -1
            }
        } onCancel: {
            cancelled.set()
            box.terminateThenKill()
        }

        await Self.waitForPipes([out, err], limit: .seconds(5))
        out.stop()
        err.stop()

        if cancelled.isSet || Task.isCancelled { throw BrewCheckError.cancelled }
        if timedOut.isSet { throw BrewCheckError.timedOut(command: command, after: timeout) }

        return CommandResult(exitCode: status, stdout: out.data, stderr: err.data)
    }

    /// Waits until both pipes are closed, but at most `limit`. Child processes
    /// of brew can keep a pipe open after brew itself has ended.
    private static func waitForPipes(_ readers: [PipeReader], limit: Duration) async {
        await withTaskGroup(of: Bool.self) { group in
            for reader in readers {
                group.addTask {
                    for await _ in reader.finished {}
                    return true
                }
            }
            group.addTask {
                try? await Task.sleep(for: limit)
                return false
            }

            var remaining = readers.count
            for await closed in group {
                if closed {
                    remaining -= 1
                    if remaining == 0 { break }
                } else {
                    break
                }
            }
            group.cancelAll()
        }
    }
}