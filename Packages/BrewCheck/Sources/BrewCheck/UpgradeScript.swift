import Foundation

/// Builds the contents of the temporary `.command` script that runs
/// `brew upgrade` in Terminal and afterwards asks TheTap to re-check.
/// The script waits for a key press so the user can read the output.
public enum UpgradeScript {
    public static let recheckURL = "thetap://recheck"

    /// - Parameters:
    ///   - brewPath: absolute path of the brew executable.
    ///   - greedy: whether to pass `--greedy` (casks with their own updater).
    public static func content(brewPath: String, greedy: Bool) -> String {
        let brew = shellQuoted(brewPath)
        let greedyFlag = greedy ? " --greedy" : ""
        return """
        #!/bin/zsh
        eval "$(\(brew) shellenv)"
        \(brew) upgrade\(greedyFlag) --no-ask
        echo
        echo "Fertig. TheTap aktualisiert die Liste jetzt."
        open -g "\(recheckURL)"
        read -k 1 "?Zum Schließen eine beliebige Taste drücken …"

        """
    }

    /// Wraps a string in single quotes for the shell; an embedded `'` becomes `'\''`.
    static func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}