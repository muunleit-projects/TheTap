# TheTap – Status

Stand: 20.10.2026

## Aktuelle Phase

Phase 2 – CLI: abgenommen.
Nächste Phase: Phase 3 – App-Gerüst (`project.yml`, `MenuBarExtra`, `AppState`, Panel).

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Letzter Commit der Phase 2: `ac6c0b0`.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0.
- VS Code mit der Swift-Erweiterung (swiftlang) ist installiert.
- CI: `.github/workflows/ci.yml` läuft auf dem Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3. Der Mac hat also ein neueres Swift (6.4) als die CI. Deshalb `swift-tools-version: 6.0` in `Package.swift` verwenden und keine APIs benutzen, die erst mit Xcode 27 kommen.
- Die CI-Schritte „Run package tests“ und „Build app“ laufen nur, wenn `Packages/BrewCheck/Package.swift` bzw. `scripts/build.sh` existieren. In Phase 3 die `if:`-Bedingungen entfernen, damit nichts still übersprungen wird.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen (GitHub sperrt den automatischen Zugriff auf die Unterordner). Dateien, um die es geht, lädt der Nutzer in den Chat hoch oder kopiert sie hinein.

## Erledigt

- Phase 0: Werkzeuge, Repo, `.gitignore`, `docs/PLAN.md`, `docs/STATUS.md`, `.vscode/` (extensions.json, tasks.json) und CI.
- Phase 1: Package `Packages/BrewCheck` mit Bibliothek `BrewCheck` (Models, BrewLocator, CommandRunner, ProcessRunner, OutdatedParser, BrewChecker, Policies) und Tests. `BrewChecker.init`-Parameter: `runner`, `locator`, `baseEnvironment`, `updateTimeout`, `outdatedTimeout`.
- Phase 2, Bibliothek: `BrewCheckError+Message.swift` mit `BrewCheckError.userMessage` (deutsche Kurztexte, für CLI und App gemeinsam); Test `ErrorMessageTests.swift`.
- Phase 2, CLI (`Sources/BrewCheckCLI/`): `CLIOptions.swift` (Optionen `--no-update`, `--no-greedy`, `--json`, Exit-Code 2 bei unbekannter Option), `OutputFormatter.swift` (Tabelle „Formulae“/„Casks“, „(angepinnt)“, „Alles aktuell.“, JSON mit den Feldnamen von `OutdatedPackage`), `ErrorOutput.swift` (Fehler auf stderr mit `userMessage` plus Befehl, Exit-Code und letzten 20 Ausgabezeilen), `main.swift`.
- 53 Tests in 5 Suites, lokal und in der CI grün.
- Phase-2-Abnahme: Liste identisch mit `brew outdated --greedy` und `brew outdated`; Fehler ohne Netz verständlich, Exit-Code 1.

## Erkenntnisse

- `brew outdated --json=v2 --greedy` liefert Exit-Code 0, auch wenn Pakete veraltet sind. Exit-Code ungleich 0 ist also ein Fehler; `BrewChecker` parst dann nichts.
- `real.json` enthält nur ein Cask (`losslesscut`) und keine Formulae; Formulae und angepinnte Pakete kommen über selbst geschriebene Fixtures.
- Die GitHub-Runner setzen `HOMEBREW_NO_AUTO_UPDATE=1` selbst. Tests dürfen nie von der Umgebung der Maschine abhängen; `BrewChecker` bekommt `baseEnvironment` als Parameter. Prüfung: `HOMEBREW_NO_AUTO_UPDATE=1 swift test`.
- `PackageKey` = Name + Art + `currentVersion`. Eine neue Version desselben Pakets zählt als neu. Ein in der Zukunft liegender Zeitpunkt der letzten Prüfung gilt als „Prüfung fällig“.
- Die Testausgabe nennt `Target Platform: arm64e-apple-macos14.0`; das ist nur die Anzeige des Test-Frameworks. Die Zeile „Executed 0 tests“ ist normal.
- Ohne Netz scheitert `brew update` mit Exit-Code 1 und „Could not resolve host“. Die App muss das später als „Offline“ erkennen (Netzwerkstatus), nicht als Fehler zeigen.
- `brew outdated` aktualisiert die Homebrew-API-Daten selbst, wenn `HOMEBREW_NO_AUTO_UPDATE` nicht gesetzt ist. Deshalb zeigt ein Lauf mit `--no-update` ggf. weniger Pakete als ein manueller `brew outdated`.
- Swift 6 erlaubt Top-Level-`await` in `main.swift`; `exit(n)` beendet die CLI mit dem Exit-Code.

## Offene Probleme

- `.vscode/settings.json` gibt es bewusst nicht: Die Einstellung `swift.searchSubfoldersForPackages` existiert in der installierten Erweiterung nicht (vorhanden ist `swift.ignoreSearchingForPackagesInSubfolders`). Noch zu prüfen: Findet die Erweiterung `Packages/BrewCheck` von selbst (keine roten Fehler in den Quelldateien, Tests in der Seitenleiste)? Falls nicht, passende Einstellung ergänzen.
- Terminal-App für `.command`-Dateien (Phase 4), Signierung (Phase 5) und Standardwerte (nach einer Woche Alltag) sind weiter offen, siehe PLAN.md.

## Nächster Schritt

Phase 3: `project.yml` (Deployment Target macOS 26, Swift 6, Bundle-ID `io.github.muunleit-projects.thetap`, `LSUIElement = YES`, URL-Schema `thetap`, ohne Sandbox, Ad-hoc-Signierung, lokales Package `Packages/BrewCheck`), `scripts/build.sh`, danach App mit `MenuBarExtra`, `AppState` und Panel. Dabei in `ci.yml` die `if:`-Bedingungen der Schritte „Run package tests“ und „Build app“ entfernen. SF Symbols (`mug`, `mug.fill`, `arrow.triangle.2.circlepath`, `exclamationmark.triangle`) vor der Verwendung prüfen. Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`, `Packages/BrewCheck/Package.swift`, `.github/workflows/ci.yml`, `.vscode/tasks.json`, `.gitignore`.
