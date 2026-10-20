import BrewCheck
import Foundation

func printError(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

/// Short German message plus a few technical details, since the CLI has no log file.
func describe(_ error: BrewCheckError) -> String {
    var lines = ["Fehler: \(error.userMessage)"]
    switch error {
    case .commandFailed(let command, let exitCode, let output):
        lines.append("Befehl: \(command.joined(separator: " "))")
        lines.append("Exit-Code: \(exitCode)")
        let tail = output.split(separator: "\n", omittingEmptySubsequences: true).suffix(20)
        lines.append(contentsOf: tail.map { "  \($0)" })
    case .timedOut(let command, let after):
        lines.append("Befehl: \(command.joined(separator: " "))")
        lines.append("Zeitlimit: \(after)")
    case .invalidJSON(let text):
        lines.append("Anfang der Ausgabe: \(text)")
    case .brewNotFound(let searched):
        lines.append("Geprüft: \(searched.joined(separator: ", "))")
    case .cancelled:
        break
    }
    return lines.joined(separator: "\n")
}