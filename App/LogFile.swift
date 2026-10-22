import Foundation
import os

/// Writes error details to `~/Library/Logs/TheTap/thetap.log`. Starting at
/// `maxBytes` the file is renamed to `thetap.log.1` (replacing an older one)
/// and a new file begins. A failure to write is only logged to the system log
/// and never reaches the user.
@MainActor
final class LogFile {
    static let fileName = "thetap.log"
    static let rotatedFileName = "thetap.log.1"

    let directory: URL
    let url: URL
    private let maxBytes: Int
    private let logger = Logger(
        subsystem: "io.github.muunleit-projects.thetap", category: "check")

    init(directory: URL? = nil, maxBytes: Int = 1_000_000) {
        let dir =
            directory
            ?? URL.homeDirectory.appending(path: "Library/Logs/TheTap", directoryHint: .isDirectory)
        self.directory = dir
        self.url = dir.appending(path: Self.fileName, directoryHint: .notDirectory)
        self.maxBytes = maxBytes
    }

    /// Appends one entry with a time stamp, followed by a blank line.
    func write(_ message: String, date: Date = Date()) {
        let entry = "[\(Self.timestamp(date))] \(message)\n\n"
        do {
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true)
            rotateIfNeeded()
            try append(Data(entry.utf8))
        } catch {
            logger.error(
                "Could not write the log file: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func append(_ data: Data) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
    }

    private func rotateIfNeeded() {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attributes?[.size] as? NSNumber)?.intValue ?? 0
        guard size >= maxBytes else { return }
        let rotated = directory.appending(path: Self.rotatedFileName, directoryHint: .notDirectory)
        do {
            if FileManager.default.fileExists(atPath: rotated.path) {
                try FileManager.default.removeItem(at: rotated)
            }
            try FileManager.default.moveItem(at: url, to: rotated)
            logger.notice("Log file rotated")
        } catch {
            logger.error(
                "Could not rotate the log file: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func timestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}