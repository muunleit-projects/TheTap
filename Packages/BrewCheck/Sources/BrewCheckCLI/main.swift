import BrewCheck
import Foundation

let options: CLIOptions
do {
    options = try CLIOptions.parse(Array(CommandLine.arguments.dropFirst()))
} catch CLIOptions.ParseError.unknownOption(let option) {
    printError("Unbekannte Option: \(option)")
    printError(CLIOptions.usage)
    exit(2)
} catch {
    printError(CLIOptions.usage)
    exit(2)
}

let checker = BrewChecker()
do {
    let packages = try await checker.outdated(runUpdate: options.runUpdate, greedy: options.greedy)
    if options.json {
        print(try OutputFormatter.json(packages))
    } else {
        print(OutputFormatter.table(packages))
    }
    exit(0)
} catch let error as BrewCheckError {
    printError(describe(error))
    exit(1)
} catch {
    printError("Fehler: \(error.localizedDescription)")
    exit(1)
}