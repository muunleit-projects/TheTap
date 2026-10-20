# TheTap – Status

Stand: 20.10.2026

## Aktuelle Phase

Phase 1 – Kernbibliothek mit Tests, in Arbeit.
Fertig: Package-Gerüst, Datenmodell, `BrewLocator`. Offen: `ProcessRunner`, `OutdatedParser`, `BrewChecker`, `Policies` und die restlichen Fixtures.

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0.
- VS Code mit der Swift-Erweiterung (swiftlang) ist installiert.
- CI: `.github/workflows/ci.yml` läuft auf dem Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3. Der Mac hat also ein neueres Swift (6.4) als die CI. Deshalb `swift-tools-version: 6.0` in `Package.swift` verwenden und keine APIs benutzen, die erst mit Xcode 27 kommen.
- Die CI-Schritte „Run package tests“ und „Build app“ laufen nur, wenn `Packages/BrewCheck/Package.swift` bzw. `scripts/build.sh` existieren. In Phase 3 die `if:`-Bedingungen entfernen, damit nichts still übersprungen wird.

## Erledigt

- Phase 0: Werkzeuge, Repo, `.gitignore`, `docs/PLAN.md`, `docs/STATUS.md`, `.vscode/` (extensions.json, tasks.json) und CI sind angelegt; der erste CI-Lauf ist grün.
- Phase 1, Gerüst: `Packages/BrewCheck/Package.swift` (tools 6.0, `platforms: [.macOS("26.0")]`, Swift-Sprachmodus 6), Bibliothek `BrewCheck`, ausführbares Produkt `brewcheck-cli` (noch Platzhalter), Testziel mit `Fixtures/` als Ressource. `dump-package` bestätigt macOS 26.0.
- Phase 1, Datenmodell: `Models.swift` mit `PackageKind`, `OutdatedPackage`, `BrewCheckError`.
- Phase 1, `BrewLocator`: `BrewLocator.swift` mit injizierbarem `PATH` und injizierter Dateiprüfung; 5 Tests (PATH, Apple Silicon, Intel, nichts gefunden, keine doppelten Pfade).
- `real.json` erzeugt (`Tests/BrewCheckTests/Fixtures/real.json`).
- `swift build` und `swift test` sind grün: 6 Tests bestanden. Die Zeile „Executed 0 tests“ des alten XCTest-Läufers ist normal, weil nur Swift Testing verwendet wird.

## Erkenntnisse

- `brew outdated --json=v2 --greedy` liefert Exit-Code 0, auch wenn Pakete veraltet sind. Exit-Code ungleich 0 ist also ein Fehler. Damit ist der Punkt aus PLAN.md („Prüfe einmal am echten System …“) erledigt.
- `real.json` enthält nur ein Cask (`losslesscut`, 3.69.0 → 3.70.1) und keine Formulae; `pinned_version` ist `null`. Fälle mit Formulae und angepinnten Paketen kommen über selbst geschriebene Fixtures (`pinned.json` usw.).
- Die Testausgabe nennt `Target Platform: arm64e-apple-macos14.0`. Das ist nur die Anzeige des Test-Frameworks; die Package-Plattform ist macOS 26.0.

## Offene Probleme

- `.vscode/settings.json` gibt es bewusst nicht: Die Einstellung `swift.searchSubfoldersForPackages` existiert in der installierten Erweiterung nicht (vorhanden ist `swift.ignoreSearchingForPackagesInSubfolders`). Noch zu prüfen: Findet die Erweiterung `Packages/BrewCheck` von selbst (keine roten Fehler in den Quelldateien, Tests in der Seitenleiste)? Falls nicht, passende Einstellung ergänzen.
- Ergebnis der CI nach dem ersten Push mit Package ist noch nicht gemeldet (erster Lauf, in dem `swift test` wirklich ausgeführt wird).
- `BrewLocator` und die Tests sind lokal grün, aber noch nicht committet und gepusht.
- Terminal-App für `.command`-Dateien (Phase 4), Signierung (Phase 5) und Standardwerte (nach einer Woche Alltag) sind weiter offen, siehe PLAN.md.

## Nächster Schritt

`ProcessRunner` (Protokoll `CommandRunner`, `CommandResult`) mit den Tests aus der Teststrategie: Ausgabe, Exit-Code, getrennte Streams, große Ausgabe, Timeout, Abbruch. Danach `OutdatedParser` mit den Fixtures, `BrewChecker` mit `FakeRunner` und `Policies`.
