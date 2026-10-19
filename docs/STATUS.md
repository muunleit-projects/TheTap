# TheTap – Status

Stand: 19.10.2026

## Aktuelle Phase

Phase 0 abgeschlossen (alle Abnahmekriterien vom Nutzer geprüft).
Als Nächstes: Phase 1 – Kernbibliothek mit Tests.

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0.
- VS Code mit der Swift-Erweiterung (swiftlang) ist installiert.
- CI: `.github/workflows/ci.yml` läuft auf dem Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3. Der Mac hat also ein neueres Swift (6.4) als die CI. Deshalb `swift-tools-version: 6.0` in `Package.swift` verwenden und keine APIs benutzen, die erst mit Xcode 27 kommen.
- Die CI-Schritte „Run package tests“ und „Build app“ laufen nur, wenn `Packages/BrewCheck/Package.swift` bzw. `scripts/build.sh` existieren. In Phase 3 die `if:`-Bedingungen entfernen, damit nichts still übersprungen wird.

## Erledigt

- Phase 0: Werkzeuge, Repo, `.gitignore`, `docs/PLAN.md`, `docs/STATUS.md`, `.vscode/` (extensions.json, tasks.json) und CI sind angelegt; der erste CI-Lauf ist grün.

## Offene Probleme

- `.vscode/settings.json` gibt es bewusst nicht: Die Einstellung `swift.searchSubfoldersForPackages` existiert in der installierten Erweiterung nicht (vorhanden ist `swift.ignoreSearchingForPackagesInSubfolders`). In Phase 1 prüfen, ob die Erweiterung `Packages/BrewCheck` von selbst findet; falls nicht, passende Einstellung ergänzen.
- Terminal-App für `.command`-Dateien (Phase 4), Signierung (Phase 5) und Standardwerte (nach einer Woche Alltag) sind weiter offen, siehe PLAN.md.

## Nächster Schritt

Phase 1 beginnen: Ordner `Packages/BrewCheck` mit Fixtures anlegen und die echte `real.json` erzeugen (`brew outdated --json=v2 --greedy`).
