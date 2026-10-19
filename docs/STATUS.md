# TheTap – Status

Stand: 19.10.2026

## Aktuelle Phase

Phase 0 – Werkzeuge und Repo

## Erledigt

- Swift 6.4 ist installiert (`swift --version`).
- Xcode 27.1 ist installiert und aktiv (`xcodebuild -version`). Der Plan nennt Xcode 26, installiert wurde die neuere Version. Das Deployment Target bleibt macOS 26.
- `xcodegen` 2.46.0, Homebrew 7.0.9 und git 2.54.0 sind vorhanden.
- Die Swift-Erweiterung (swiftlang) ist in VS Code installiert.
- Das Repo `muunleit-projects/TheTap` ist angelegt und geklont nach `~/Programmieren/swift/TheTap`.
- `.gitignore`, `docs/STATUS.md` und `docs/PLAN.md` sind angelegt.

## Offene Probleme

- CI-Runner: Prüfen, welches GitHub-Actions-Image macOS 26 mit Xcode bietet, und `ci.yml` darauf festlegen. Auf dem Mac läuft Xcode 27.1, der Runner kann ein anderes Xcode haben.

## Nächster Schritt

`.vscode/` (tasks.json, settings.json, extensions.json) und `.github/workflows/ci.yml` anlegen, dann die Abnahmekriterien von Phase 0 durchgehen.
