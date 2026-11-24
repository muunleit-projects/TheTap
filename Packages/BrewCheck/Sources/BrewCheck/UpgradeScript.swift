import Foundation

/// Builds the contents of the temporary `.command` script that runs
/// `brew upgrade` in Terminal and afterwards asks TheTap to re-check.
/// The re-check is sent once: at the normal end, or from a trap when the
/// user aborts the upgrade (Ctrl+C via INT, closing the window via EXIT).
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
        rechecked=0
        recheck() {
          if (( ! rechecked )); then
            rechecked=1
            open -g "\(recheckURL)"
          fi
        }
        trap recheck EXIT
        trap 'recheck; exit 130' INT
        \(brew) upgrade\(greedyFlag) --no-ask
        echo
        echo "Fertig. TheTap aktualisiert die Liste jetzt."
        recheck
        read -k 1 "?Zum Schließen eine beliebige Taste drücken …"

        """
    }

    /// Wraps a string in single quotes for the shell; an embedded `'` becomes `'\''`.
    static func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
