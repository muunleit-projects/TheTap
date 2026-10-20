# TheTap – Status

Stand: 20.10.2026

## Aktuelle Phase

Phase 1 – Kernbibliothek mit Tests: abgenommen.
Nächste Phase: Phase 2 – CLI (`brewcheck-cli`).

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Letzter Commit: `dd39b09`.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0.
- VS Code mit der Swift-Erweiterung (swiftlang) ist installiert.
- CI: `.github/workflows/ci.yml` läuft auf dem Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3. Der Mac hat also ein neueres Swift (6.4) als die CI. Deshalb `swift-tools-version: 6.0` in `Package.swift` verwenden und keine APIs benutzen, die erst mit Xcode 27 kommen.
- Die CI-Schritte „Run package tests“ und „Build app“ laufen nur, wenn `Packages/BrewCheck/Package.swift` bzw. `scripts/build.sh` existieren. In Phase 3 die `if:`-Bedingungen entfernen, damit nichts still übersprungen wird.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen (GitHub sperrt den automatischen Zugriff auf die Unterordner). Dateien, um die es geht, lädt der Nutzer in den Chat hoch oder kopiert sie hinein.

## Erledigt

- Phase 0: Werkzeuge, Repo, `.gitignore`, `docs/PLAN.md`, `docs/STATUS.md`, `.vscode/` (extensions.json, tasks.json) und CI.
- Phase 1, Package: `Packages/BrewCheck/Package.swift` (tools 6.0, `platforms: [.macOS("26.0")]`, Swift-Sprachmodus 6), Bibliothek `BrewCheck`, ausführbares Produkt `brewcheck-cli` (noch Platzhalter), Testziel mit `Fixtures/` als Ressource.
- Phase 1, Bibliothek (alle in `Sources/BrewCheck/`):
  - `Models.swift`: `PackageKind`, `OutdatedPackage`, `BrewCheckError`.
  - `BrewLocator.swift`: `locate()` liefert die brew-URL oder wirft `brewNotFound`; `PATH` und Dateiprüfung sind injizierbar.
  - `CommandRunner.swift`: Protokoll `CommandRunner` und `CommandResult`.
  - `ProcessRunner.swift` und `ProcessSupport.swift`: echte Umsetzung mit `Foundation.Process`, parallelem Lesen von stdout/stderr, Timeout (SIGTERM, nach 5 s SIGKILL) und Abbruch.
  - `OutdatedParser.swift`: tolerantes Parsen, Sortierung Formulae vor Casks.
  - `BrewChecker.swift`: Actor mit `outdated(runUpdate:greedy:)`. Init-Parameter: `runner`, `locator`, `baseEnvironment`, `updateTimeout`, `outdatedTimeout`.
  - `Policies.swift`: `PackageKey` (Name, Art, Version; `Codable`), `OutdatedPackage.key`, `Policies.isCheckDue`, `newlyOutdated`, `pruneNotified`, `badgeCount`.
- Phase 1, Tests: Fixtures `real`, `empty`, `formulae-only`, `casks-only`, `pinned`, `extra-fields`, `broken`, `blank`; Testdateien für Locator, ProcessRunner, Parser, BrewChecker (mit `FakeRunner`) und Policies. 50 Tests in 4 Suites, lokal und in der CI grün.
- Phase-1-Abnahme: `swift test` grün mit allen Testgruppen; der Parser liest die echte `real.json`.

## Erkenntnisse

- `brew outdated --json=v2 --greedy` liefert Exit-Code 0, auch wenn Pakete veraltet sind. Exit-Code ungleich 0 ist also ein Fehler; `BrewChecker` parst dann nichts.
- `real.json` enthält nur ein Cask (`losslesscut`, 3.69.0 → 3.70.1) und keine Formulae; `pinned_version` ist `null`. Formulae und angepinnte Pakete kommen über selbst geschriebene Fixtures.
- Die GitHub-Runner setzen `HOMEBREW_NO_AUTO_UPDATE=1` selbst. Ein Test, der die echte Prozessumgebung voraussetzte, war deshalb in der CI rot, lokal grün. Lösung: `BrewChecker` bekommt `baseEnvironment` als Parameter (Standard: echte Umgebung), die Tests geben eine feste mit. Regel für künftige Tests: nie von der Umgebung der Maschine abhängen. Prüfung gegen diesen Fehler: `HOMEBREW_NO_AUTO_UPDATE=1 swift test`.
- `PackageKey` war in PLAN.md nicht definiert. Entscheidung: Name + Art + `currentVersion`. Eine neue Version desselben Pakets zählt als neu und löst wieder eine Mitteilung aus. Ein in der Zukunft liegender Zeitpunkt der letzten Prüfung gilt als „Prüfung fällig“.
- Die Testausgabe nennt `Target Platform: arm64e-apple-macos14.0`. Das ist nur die Anzeige des Test-Frameworks; die Package-Plattform ist macOS 26.0. Die Zeile „Executed 0 tests“ des alten XCTest-Läufers ist normal, weil nur Swift Testing verwendet wird.

## Offene Probleme

- `.vscode/settings.json` gibt es bewusst nicht: Die Einstellung `swift.searchSubfoldersForPackages` existiert in der installierten Erweiterung nicht (vorhanden ist `swift.ignoreSearchingForPackagesInSubfolders`). Noch zu prüfen: Findet die Erweiterung `Packages/BrewCheck` von selbst (keine roten Fehler in den Quelldateien, Tests in der Seitenleiste)? Falls nicht, passende Einstellung ergänzen.
- Terminal-App für `.command`-Dateien (Phase 4), Signierung (Phase 5) und Standardwerte (nach einer Woche Alltag) sind weiter offen, siehe PLAN.md.

## Nächster Schritt

Phase 2: `brewcheck-cli` nach PLAN.md (Optionen `--no-update`, `--no-greedy`, `--json`; Ausgabe „Formulae“/„Casks“ mit `name  installiert → neu`, „(angepinnt)“, „Alles aktuell.“; Fehler auf stderr mit deutscher Kurzbeschreibung; Exit-Codes 0, 1, 2). Dazu im neuen Chat hochladen: `PLAN.md`, `STATUS.md`, `Packages/BrewCheck/Package.swift` und den Platzhalter in `Sources/BrewCheckCLI/`. Die deutschen Fehlertexte für `BrewCheckError` sollen in der Bibliothek liegen, damit die App sie später wiederverwendet.
