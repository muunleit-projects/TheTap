extension BrewCheckError {
    /// Short German description for the user, shared by the CLI and the app.
    /// Details (command, exit code, output) belong in the log, not here.
    public var userMessage: String {
        switch self {
        case .brewNotFound:
            return "Homebrew nicht gefunden. Erwartet unter /opt/homebrew oder /usr/local."
        case .timedOut:
            return "brew hat nicht rechtzeitig geantwortet. Neuer Versuch folgt."
        case .commandFailed:
            return "brew meldet einen Fehler. Details im Log."
        case .invalidJSON:
            return "Unerwartete Antwort von brew. Details im Log."
        case .cancelled:
            return "Die Prüfung wurde abgebrochen."
        }
    }
}