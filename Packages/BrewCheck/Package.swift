// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BrewCheck",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "BrewCheck", targets: ["BrewCheck"]),
        .executable(name: "brewcheck-cli", targets: ["BrewCheckCLI"]),
    ],
    targets: [
        .target(name: "BrewCheck"),
        .executableTarget(name: "BrewCheckCLI", dependencies: ["BrewCheck"]),
        .testTarget(
            name: "BrewCheckTests",
            dependencies: ["BrewCheck"],
            resources: [.copy("Fixtures")]
        ),
    ],
    swiftLanguageModes: [.v6]
)