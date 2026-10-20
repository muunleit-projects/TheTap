/// Command-line options of brewcheck-cli, parsed without any third-party library.
struct CLIOptions: Equatable {
    var runUpdate = true
    var greedy = true
    var json = false

    enum ParseError: Error {
        case unknownOption(String)
    }

    static let usage = """
        Aufruf: brewcheck-cli [--no-update] [--no-greedy] [--json]
          --no-update   brew update überspringen (schneller Testlauf)
          --no-greedy   Casks mit eigenem Updater nicht einbeziehen
          --json        Ausgabe als JSON statt als Tabelle
        """

    static func parse(_ arguments: [String]) throws -> CLIOptions {
        var options = CLIOptions()
        for argument in arguments {
            switch argument {
            case "--no-update": options.runUpdate = false
            case "--no-greedy": options.greedy = false
            case "--json": options.json = true
            default: throw ParseError.unknownOption(argument)
            }
        }
        return options
    }
}