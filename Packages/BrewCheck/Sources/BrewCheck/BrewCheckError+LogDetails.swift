import Foundation

extension BrewCheckError {
    /// Maximum number of output lines written to the log file.
    static let maxLoggedOutputLines = 200

    /// Details for the log file (English, for the developer): what failed,
    /// with command, exit code and the last lines of output. The short German
    /// text for the user is `userMessage`.
    public var logDetails: String {
        switch self {
        case .brewNotFound(let searched):
            return "brew not found. Searched: " + searched.joined(separator: ", ")
        case .commandFailed(let command, let exitCode, let output):
            let header = "Command failed (exit code \(exitCode)): " + command.joined(separator: " ")
            return header + "\n" + Self.lastLines(of: output, count: Self.maxLoggedOutputLines)
        case .timedOut(let command, let after):
            return "Command timed out after \(after.components.seconds) s: "
                + command.joined(separator: " ")
        case .invalidJSON(let text):
            return "Invalid JSON from brew. Start of output:\n" + text
        case .cancelled:
            return "Check was cancelled."
        }
    }

    /// The last `count` lines of `text`, without trailing blank lines.
    static func lastLines(of text: String, count: Int) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.suffix(count).joined(separator: "\n")
    }
}