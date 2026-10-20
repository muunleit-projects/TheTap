# TheTap – Status

Stand: 20.10.2026

## Aktuelle Phase

Phase 4 – Upgrade und Recheck: abgenommen.
Als Nächstes: Phase 5 – Automatik und Mitteilungen (noch nicht begonnen).

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Letzter Commit der Phase 4: `64eaa17`.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0.
- VS Code mit der Swift-Erweiterung (swiftlang) ist installiert.
- CI: `.github/workflows/ci.yml` läuft auf dem Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3. Der Mac hat also ein neueres Swift (6.4) als die CI. Deshalb `swift-tools-version: 6.0` in `Package.swift` verwenden und keine APIs benutzen, die erst mit Xcode 27 kommen.
- Die CI führt `swift test`, die Installation von XcodeGen und `scripts/build.sh` ohne `if:`-Bedingungen aus; nichts wird still übersprungen. Letzter Lauf grün.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen (GitHub sperrt den automatischen Zugriff auf die Unterordner). Dateien, um die es geht, lädt der Nutzer in den Chat hoch oder kopiert sie hinein.

## Erledigt

- Phase 0: Werkzeuge, Repo, `.gitignore`, `docs/PLAN.md`, `docs/STATUS.md`, `.vscode/` (extensions.json, tasks.json) und CI.
- Phase 1: Package `Packages/BrewCheck` mit Bibliothek `BrewCheck` (Models, BrewLocator, CommandRunner, ProcessRunner, OutdatedParser, BrewChecker, Policies) und Tests. `BrewChecker.init`-Parameter: `runner`, `locator`, `baseEnvironment`, `updateTimeout`, `outdatedTimeout`.
- Phase 2: `BrewCheckError.userMessage` (deutsche Kurztexte, für CLI und App gemeinsam) und die CLI `brewcheck-cli`. Abgenommen.
- Phase 3 (abgenommen): `project.yml`, `scripts/build.sh`, `scripts/run.sh`, `AppState`, `MenuBarLabel`, `PackageListView`, `PanelView`, `TheTapApp` mit `MenuBarExtra` im Stil `.window`.
- Phase 4 (abgenommen):
  - `UpgradeScript` in BrewCheck (`Packages/BrewCheck/Sources/BrewCheck/UpgradeScript.swift`): erzeugt den Text des `.command`-Skripts, brew-Pfad sicher in einfachen Anführungszeichen, `--greedy` nur wenn gewünscht. Tests in `UpgradeScriptTests.swift`. Gesamt: 59 Tests in 6 Suites, lokal und in der CI grün.
  - `App/UpgradeLauncher.swift` (`@MainActor enum`): schreibt `thetap-upgrade.command` ins temporäre Verzeichnis, setzt Rechte `0o755`, öffnet es mit `NSWorkspace`. Fehler als `UpgradeLaunchError` mit deutschem `userMessage`.
  - `App/AppState.swift`: `canUpgrade`, `startUpgrade(greedy:)`, `finishUpgrade()`, `recheckAfterUpgrade()` (Prüfung ohne `brew update`), `checkNow(runUpdate:)`. Der Zustand „Upgrade läuft“ endet nach 2 Stunden von selbst, falls kein Recheck kommt.
  - `App/AppDelegate.swift`: hält den `AppState` und verarbeitet `thetap://recheck` in `application(_:open:)`; unbekannte URLs werden geloggt (`os.Logger`, Kategorie `upgrade`). `TheTapApp` nutzt `@NSApplicationDelegateAdaptor` und liest den Zustand aus dem Delegate.
  - `App/Views/PanelView.swift`: Knopf „Alles aktualisieren“ in eigener Zeile (Text „Upgrade läuft im Terminal …“, solange das Upgrade läuft).
  - Abnahme: Upgrade öffnet die Terminal-App und läuft; Fenster bleibt offen bis zu einem Tastendruck; die Liste aktualisiert sich nach dem Upgrade von selbst; angepinnte Pakete bleiben sichtbar und zählen nicht mit; `open "thetap://recheck"` löst eine Prüfung aus, `thetap://foo` wird geloggt und ignoriert.

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
- `brew upgrade` kennt `--no-ask` (kurz `-y`) und `--greedy` (kurz `-g`) in der installierten Homebrew-Version.
- `.command`-Dateien öffnen sich auf dem Mac des Nutzers in der Terminal-App (nicht iTerm).
- Terminal schließt das Fenster, sobald die Shell sauber endet. Deshalb wartet das Upgrade-Skript am Ende mit `read -k 1` auf einen Tastendruck; der Recheck wird vorher ausgelöst, die Liste aktualisiert sich also schon während der Nutzer liest.
- `application(_:open:)` im `AppDelegate` empfängt URLs auch bei einer reinen `MenuBarExtra`-App ohne Fenster.
- Die `xcodebuild`-Meldung „Using the first of multiple matching destinations“ ist harmlos.

## Offene Probleme

- Scroll-Grenze der Paketliste (ab 12 Zeilen) ist ungetestet, weil bisher zu wenige Pakete veraltet waren. Risiko gering; prüfen, sobald einmal viele Pakete veraltet sind.
- `.vscode/settings.json` gibt es bewusst nicht: Die Einstellung `swift.searchSubfoldersForPackages` existiert in der installierten Erweiterung nicht (vorhanden ist `swift.ignoreSearchingForPackagesInSubfolders`). Noch zu prüfen: Findet die Erweiterung `Packages/BrewCheck` von selbst (keine roten Fehler in den Quelldateien, Tests in der Seitenleiste)? Falls nicht, passende Einstellung ergänzen.
- `startUpgrade(greedy:)` verwendet bis Phase 6 fest `greedy: true`; die Einstellung dazu kommt in Phase 6.
- Kommt `thetap://recheck` an, während gerade eine andere Prüfung läuft, ignoriert `checkNow` die Anfrage; die Liste ist dann bis zur nächsten Prüfung veraltet. Beim Bau des Schedulers in Phase 5 bedenken.
- Bewusst noch nicht umgesetzt (spätere Phasen): „Offline“-Erkennung und Wiederholung nach Fehlschlägen (Phase 5; `consecutiveFailures` wird bereits gezählt, ein Fehler wird aktuell sofort angezeigt), Mitteilungen und `UNUserNotificationCenterDelegate` im `AppDelegate` (Phase 5), „Log öffnen“ und Logdatei (Phase 6), Einstellungen (Phase 6).
- Signierung (Phase 5) und Standardwerte (nach einer Woche Alltag) sind weiter offen, siehe PLAN.md.

## Nächster Schritt

Phase 5 – Automatik und Mitteilungen: `Scheduler` (Start nach 10 Sekunden, `NSBackgroundActivityScheduler`, Aufwachen, `NWPathMonitor`, Wiederholung nach Fehlschlägen), `Notifier` mit `UserNotifications`, Offline-Phase.
Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`, `App/AppState.swift`, `App/AppDelegate.swift`, `App/TheTapApp.swift`, `App/Views/PanelView.swift`, `project.yml`, `Packages/BrewCheck/Sources/BrewCheck/Policies.swift`.
