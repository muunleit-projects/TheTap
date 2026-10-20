import Foundation

/// A thread-safe on/off switch.
final class Flag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    func set() {
        lock.lock()
        value = true
        lock.unlock()
    }

    var isSet: Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

/// Wraps a `Process` (which is not `Sendable`) so it can be stopped from
/// another task.
final class ProcessBox: @unchecked Sendable {
    let process = Process()

    /// SIGTERM now, SIGKILL after `delay` seconds if it is still running.
    func terminateThenKill(after delay: TimeInterval = 5) {
        guard process.isRunning else { return }
        process.terminate()

        let pid = process.processIdentifier
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [self] in
            if process.isRunning { kill(pid, SIGKILL) }
        }
    }
}

/// Collects everything a pipe delivers while the process runs.
final class PipeReader: @unchecked Sendable {
    /// Ends (finishes) when the pipe is closed.
    let finished: AsyncStream<Void>

    private let continuation: AsyncStream<Void>.Continuation
    private let handle: FileHandle
    private let lock = NSLock()
    private var buffer = Data()

    init(_ handle: FileHandle) {
        let pair = AsyncStream<Void>.makeStream()
        self.finished = pair.stream
        self.continuation = pair.continuation
        self.handle = handle

        handle.readabilityHandler = { [weak self] readable in
            let chunk = readable.availableData
            guard let self else { return }

            if chunk.isEmpty {
                // Empty data means end of file.
                readable.readabilityHandler = nil
                self.continuation.finish()
                return
            }

            self.lock.lock()
            self.buffer.append(chunk)
            self.lock.unlock()
        }
    }

    func stop() {
        handle.readabilityHandler = nil
        continuation.finish()
    }

    var data: Data {
        lock.lock()
        defer { lock.unlock() }
        return buffer
    }
}