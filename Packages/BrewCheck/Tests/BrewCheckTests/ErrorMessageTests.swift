import Testing
@testable import BrewCheck

@Suite("BrewCheckError.userMessage")
struct ErrorMessageTests {
    @Test func brewNotFoundMentionsExpectedLocations() {
        let error = BrewCheckError.brewNotFound(searched: ["/opt/homebrew/bin/brew"])
        #expect(error.userMessage.contains("/opt/homebrew"))
        #expect(error.userMessage.contains("/usr/local"))
    }

    @Test func cancelledHasMessage() {
        #expect(!BrewCheckError.cancelled.userMessage.isEmpty)
    }

    @Test func invalidJSONHasMessage() {
        #expect(BrewCheckError.invalidJSON("x").userMessage.contains("Unerwartete Antwort"))
    }
}