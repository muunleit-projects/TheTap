# TheTap – Status

Stand: 20.10.2026

## Aktuelle Phase

Phase 3 – App-Gerüst: abgenommen.
Als Nächstes: Phase 4 – Upgrade und Recheck (noch nicht begonnen).

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Letzter Commit der Phase 3: `f558210`.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0.
- VS Code mit der Swift-Erweiterung (swiftlang) ist installiert.
- CI: `.github/workflows/ci.yml` läuft auf dem Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3. Der Mac hat also ein neueres Swift (6.4) als die CI. Deshalb `swift-tools-version: 6.0` in `Package.swift` verwenden und keine APIs benutzen, die erst mit Xcode 27 kommen.
- Die CI führt `swift test`, die Installation von XcodeGen und `scripts/build.sh` ohne `if:`-Bedingungen aus; nichts wird still übersprungen. Letzter Lauf grün.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen (GitHub sperrt den automatischen Zugriff auf die Unterordner). Dateien, um die es geht, lädt der Nutzer in den Chat hoch oder kopiert sie hinein.

## Erledigt

- Phase 0: Werkzeuge, Repo, `.gitignore`, `docs/PLAN.md`, `docs/STATUS.md`, `.vscode/` (extensions.json, tasks.json) und CI.
- Phase 1: Package `Packages/BrewCheck` mit Bibliothek `BrewCheck` (Models, BrewLocator, CommandRunner, ProcessRunner, OutdatedParser, BrewChecker, Policies) und Tests. `BrewChecker.init`-Parameter: `runner`, `locator`, `baseEnvironment`, `updateTimeout`, `outdatedTimeout`.
- Phase 2: `BrewCheckError.userMessage` (deutsche Kurztexte, für CLI und App gemeinsam) und die CLI `brewcheck-cli` (`CLIOptions`, `OutputFormatter`, `ErrorOutput`, `main`). 53 Tests in 5 Suites, lokal und in der CI grün. Abgenommen.
- Phase 3 (abgenommen):
  - Schritt 1 (Commit `6bcf3d5`): `project.yml`, `scripts/build.sh`, `App/TheTapApp.swift`, generierte `App/Info.plist`, angepasste `ci.yml`.
    - `project.yml`: Deployment Target macOS 26, Swift 6, Bundle-ID `io.github.muunleit-projects.thetap`, `LSUIElement = YES`, URL-Schema `thetap`, keine Sandbox, Ad-hoc-Signierung, lokales Package `Packages/BrewCheck`.
    - `App/Info.plist` wird von XcodeGen aus `project.yml` erzeugt und ist eingecheckt; sie steht in `excludes` der Quellen. Keine Warnung dazu aufgetreten.
  - Schritt 2 (Commit `d659f46`): `App/AppState.swift` (`@MainActor @Observable`, Phasen `notChecked`, `checking`, `upToDate`, `updatesAvailable`, `offline`, `failed`; hält `packages`, `lastSuccess`, `lastErrorMessage`, `consecutiveFailures`, `upgradeRunning`; `badgeCount`, `statusText`, `checkNow()`), `App/Views/MenuBarLabel.swift`, `PackageListView.swift`, `PanelView.swift`, `App/TheTapApp.swift` (`@State`-Zustand, `MenuBarExtra` im Stil `.window`).
  - Schritt 3 (Commit `f558210`): `scripts/run.sh` baut zuerst, beendet danach eine laufende Instanz (`pkill -x TheTap`) und startet die neue App. CI grün.
  - Abnahme: Build lokal und in der CI grün; Tasks „App bauen“ und „App starten“ funktionieren, danach läuft genau eine Instanz; App ohne Dock-Icon mit Becher-Icon in der Menüleiste; „Jetzt prüfen“ zeigt die echten Pakete, das Panel bleibt währenddessen bedienbar; `mug.fill` mit Zahl stimmt mit der Zahl der nicht angepinnten Pakete überein; das Fehler-Icon `exclamationmark.triangle` erscheint ohne Netz; Pin-Symbol bei angepinnten Paketen.

## Erkenntnisse

- `brew outdated --json=v2 --greedy` liefert Exit-Code 0, auch wenn Pakete veraltet sind. Exit-Code ungleich 0 ist also ein Fehler; `BrewChecker` parst dann nichts.
- `real.json` enthält nur ein Cask (`losslesscut`) und keine Formulae; Formulae und angepinnte Pakete kommen über selbst geschriebene Fixtures.
- Die GitHub-Runner setzen `HOMEBREW_NO_AUTO_UPDATE=1` selbst. Tests dürfen nie von der Umgebung der Maschine abhängen; `BrewChecker` bekommt `baseEnvironment` als Parameter. Prüfung: `HOMEBREW_NO_AUTO_UPDATE=1 swift test`.
- `PackageKey` = Name + Art + `currentVersion`. Eine neue Version desselben Pakets zählt als neu. Ein in der Zukunft liegender Zeitpunkt der letzten Prüfung gilt als „Prüfung fällig“.
- Die Testausgabe nennt `Target Platform: arm64e-apple-macos14.0`; das ist nur die Anzeige des Test-Frameworks. Die Zeile „Executed 0 tests“ ist normal.
- Ohne Netz scheitert `brew update` mit Exit-Code 1 und „Could not resolve host“. Die App muss das später als „Offline“ erkennen (Netzwerkstatus), nicht als Fehler zeigen. Aktuell erscheint ohne Netz noch das Fehler-Icon; das ist bis Phase 5 gewollt.
- `brew outdated` aktualisiert die Homebrew-API-Daten selbst, wenn `HOMEBREW_NO_AUTO_UPDATE` nicht gesetzt ist. Deshalb zeigt ein Lauf mit `--no-update` ggf. weniger Pakete als ein manueller `brew outdated`.
- Swift 6 erlaubt Top-Level-`await` in `main.swift`; `exit(n)` beendet die CLI mit dem Exit-Code.
- `scripts/build.sh` baut mit `-derivedDataPath build`; die App liegt danach unter `build/Build/Products/Debug/TheTap.app`. `scripts/run.sh` beendet die laufende Instanz selbst; wer die App von Hand mit `open` startet, muss sie vorher über „Beenden“ schließen.
- SF Symbols auf dem Mac des Nutzers bestätigt: `mug`, `mug.fill`, `arrow.triangle.2.circlepath`, `pin`, `exclamationmark.triangle`.

## Offene Probleme

- Scroll-Grenze der Paketliste (ab 12 Zeilen) ist ungetestet, weil bisher zu wenige Pakete veraltet waren. Risiko gering; prüfen, sobald einmal viele Pakete veraltet sind.
- `.vscode/settings.json` gibt es bewusst nicht: Die Einstellung `swift.searchSubfoldersForPackages` existiert in der installierten Erweiterung nicht (vorhanden ist `swift.ignoreSearchingForPackagesInSubfolders`). Noch zu prüfen: Findet die Erweiterung `Packages/BrewCheck` von selbst (keine roten Fehler in den Quelldateien, Tests in der Seitenleiste)? Falls nicht, passende Einstellung ergänzen.
- Bewusst noch nicht umgesetzt (spätere Phasen): „Alles aktualisieren“ (Phase 4), „Offline“-Erkennung und Wiederholung nach Fehlschlägen (Phase 5; `consecutiveFailures` wird bereits gezählt, ein Fehler wird aktuell sofort angezeigt), „Log öffnen“ und Logdatei (Phase 6), Einstellungen (Phase 6).
- Terminal-App für `.command`-Dateien (Phase 4), Signierung (Phase 5) und Standardwerte (nach einer Woche Alltag) sind weiter offen, siehe PLAN.md.

## Nächster Schritt

Phase 4 – Upgrade und Recheck: `UpgradeLauncher` (temporäres `.command`-Skript), URL-Schema `thetap://recheck` mit `AppDelegate`, Zustand „Upgrade läuft“ und der Knopf „Alles aktualisieren“.
Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`, `App/AppState.swift`, `App/TheTapApp.swift`, `App/Views/PanelView.swift`, `project.yml`.
