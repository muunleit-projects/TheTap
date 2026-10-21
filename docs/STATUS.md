# TheTap – Status

Stand: 21.10.2026

## Aktuelle Phase

Phase 5 – Automatik und Mitteilungen: Schritte 1 bis 3 von 7 sind fertig, geprüft und gepusht.
Als Nächstes: Schritt 4 (Scheduler), noch nicht begonnen.

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Letzter Code-Commit: `56688cb` (Phase 5, Schritt 3); danach `6dfdfcd` (nur `PLAN.md` und `RELEASE.md`). Commits der Phase 5: `8c568ca` (Schritt 1), `af55f21` (Schritt 2), `56688cb` (Schritt 3). Phase 4 endete mit `64eaa17`.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0.
- VS Code mit der Swift-Erweiterung (swiftlang) ist installiert.
- CI: `.github/workflows/ci.yml` läuft auf dem Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3, also älter als der Mac. Regeln dazu in PLAN.md unter „Feste Entscheidungen → Toolchain“.
- Die CI führt `swift test`, die Installation von XcodeGen und `scripts/build.sh` ohne `if:`-Bedingungen aus; nichts wird still übersprungen. Letzter Lauf grün.
- Tests: 73 Tests in 6 Suites, lokal (auch mit `HOMEBREW_NO_AUTO_UPDATE=1`) und in der CI grün.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen (GitHub sperrt den automatischen Zugriff auf die Unterordner). Dateien, um die es geht, lädt der Nutzer in den Chat hoch oder kopiert sie hinein.

## Erledigt

- Phase 0: Werkzeuge, Repo, `.gitignore`, `docs/PLAN.md`, `docs/STATUS.md`, `.vscode/` (extensions.json, tasks.json) und CI.
- Phase 1: Package `Packages/BrewCheck` mit Bibliothek `BrewCheck` (Models, BrewLocator, CommandRunner, ProcessRunner, OutdatedParser, BrewChecker, Policies) und Tests. `BrewChecker.init`-Parameter: `runner`, `locator`, `baseEnvironment`, `updateTimeout`, `outdatedTimeout`.
- Phase 2: `BrewCheckError.userMessage` (deutsche Kurztexte, für CLI und App gemeinsam) und die CLI `brewcheck-cli`. Abgenommen.
- Phase 3 (abgenommen): `project.yml`, `scripts/build.sh`, `scripts/run.sh`, `AppState`, `MenuBarLabel`, `PackageListView`, `PanelView`, `TheTapApp` mit `MenuBarExtra` im Stil `.window`.
- Phase 4 (abgenommen): `UpgradeScript` in BrewCheck, `App/UpgradeLauncher.swift`, `AppState` mit `canUpgrade`, `startUpgrade(greedy:)`, `finishUpgrade()`, `recheckAfterUpgrade()`; `AppDelegate` verarbeitet `thetap://recheck` in `application(_:open:)`; Knopf „Alles aktualisieren“ im Panel. Der Zustand „Upgrade läuft“ endet nach 2 Stunden von selbst, falls kein Recheck kommt.
- Phase 5, Schritt 1 (`8c568ca`, abgenommen): `App/NetworkMonitor.swift` (`@MainActor`, `NWPathMonitor`, meldet über `onChange`); `AppDelegate` startet ihn in `applicationDidFinishLaunching`, loggt jede Änderung (Kategorie `scheduler`) und ruft `AppState.networkChanged(isOnline:)`. `AppState.isOnline`; ein Fehlschlag ohne Netz ergibt „Offline“ statt „Fehler“ (`failCheck`).
- Phase 5, Schritt 2 (`af55f21`, abgenommen): In `Policies`: `failuresBeforeError = 3`, `showsFailure(consecutiveFailures:manual:)`, Struktur `NotificationText` und `notificationText(newPackages:badgeCount:)`; 14 neue Tests in `PoliciesTests`. Festlegung: `consecutiveFailures` zählt den aktuellen Fehlschlag mit, ein automatischer Fehler wird also ab dem 3. Fehlschlag in Folge sichtbar.
- Phase 5, Schritt 3 (`56688cb`, abgenommen): `AppState.checkIfDue()` prüft nacheinander: läuft keine Prüfung, läuft kein Upgrade, ist das Netz da (sonst Phase „Offline“), ist `isCheckDue` wahr; jede Entscheidung wird geloggt (Kategorie `scheduler`). `AppState.checkInterval` liest den `UserDefaults`-Schlüssel `checkInterval` bei jedem Zugriff (Standard 21600 s). `checkNow` ruft intern `performCheck`; ein Recheck, der während einer Prüfung kommt, wird vorgemerkt (`recheckPending`) und läuft direkt danach ohne `brew update`. `networkChanged` nutzt `checkIfDue()`; war nichts fällig, kehrt die Phase zum vorigen Stand zurück (`restorePhase()`).
  - Von Hand geprüft per Log (Intervall 180 s): Recheck während einer Prüfung wird vorgemerkt und danach ausgeführt; Netz kurz weg → „Skipped: not due yet“; Netz über 3 Minuten weg → „Starting check“. Damit sind die ersten beiden Abnahmekriterien der Phase 5 geprüft.
- Dokumentation: `PLAN.md` (Phase 5 in 7 Schritten, Phase 7 geteilt in 7a und 7b) und `docs/RELEASE.md` (Release-Anleitung samt `release.yml`) liegen im Repo.

## Erkenntnisse

- `brew outdated --json=v2 --greedy` liefert Exit-Code 0, auch wenn Pakete veraltet sind. Exit-Code ungleich 0 ist also ein Fehler; `BrewChecker` parst dann nichts.
- `real.json` enthält nur ein Cask (`losslesscut`) und keine Formulae; Formulae und angepinnte Pakete kommen über selbst geschriebene Fixtures.
- Die GitHub-Runner setzen `HOMEBREW_NO_AUTO_UPDATE=1` selbst. Tests dürfen nie von der Umgebung der Maschine abhängen; `BrewChecker` bekommt `baseEnvironment` als Parameter. Prüfung: `HOMEBREW_NO_AUTO_UPDATE=1 swift test`.
- `PackageKey` = Name + Art + `currentVersion`. Eine neue Version desselben Pakets zählt als neu. Ein in der Zukunft liegender Zeitpunkt der letzten Prüfung gilt als „Prüfung fällig“.
- Die Testausgabe zählt 6 Suites, obwohl es 8 Testdateien gibt: `BrewLocatorTests` und `ModelsTests` haben kein `@Suite`. Das ist harmlos. Die Testausgabe nennt außerdem `Target Platform: arm64e-apple-macos14.0`; das ist nur die Anzeige des Test-Frameworks.
- Ohne Netz scheitert `brew update` mit Exit-Code 1 und „Could not resolve host“. Die App zeigt dann „Offline“ statt des Fehler-Icons, sofern `NWPathMonitor` das Netz als weg meldet.
- `NWPathMonitor` meldet bei einem Wechsel mehrfach (z. B. zweimal „offline“ kurz nacheinander). Der `AppDelegate` loggt jede Meldung; `AppState.networkChanged` ignoriert eine Meldung ohne Statuswechsel.
- `brew outdated` aktualisiert die Homebrew-API-Daten selbst, wenn `HOMEBREW_NO_AUTO_UPDATE` nicht gesetzt ist. Deshalb zeigt ein Lauf mit `--no-update` ggf. weniger Pakete als ein manueller `brew outdated`.
- Swift 6 erlaubt Top-Level-`await` in `main.swift`; `exit(n)` beendet die CLI mit dem Exit-Code.
- Swift 6: Eine als `nonisolated` markierte Funktion darf nicht auf Konstanten einer `@MainActor`-Klasse zugreifen (Fehler „main actor-isolated static property … can not be referenced from a nonisolated context“).
- Das Log der App lässt sich im Terminal mitlesen: `log stream --predicate 'subsystem == "io.github.muunleit-projects.thetap"'`. `Logger.notice`-Meldungen erscheinen dort ohne weitere Optionen.
- `scripts/build.sh` baut mit `-derivedDataPath build`; die App liegt danach unter `build/Build/Products/Debug/TheTap.app`. `scripts/run.sh` beendet die laufende Instanz selbst; wer die App von Hand mit `open` startet, muss sie vorher über „Beenden“ schließen.
- SF Symbols auf dem Mac des Nutzers bestätigt: `mug`, `mug.fill`, `arrow.triangle.2.circlepath`, `pin`, `exclamationmark.triangle`.
- `brew upgrade` kennt `--no-ask` (kurz `-y`) und `--greedy` (kurz `-g`) in der installierten Homebrew-Version.
- `.command`-Dateien öffnen sich auf dem Mac des Nutzers in der Terminal-App (nicht iTerm).
- Terminal schließt das Fenster, sobald die Shell sauber endet. Deshalb wartet das Upgrade-Skript am Ende mit `read -k 1` auf einen Tastendruck; der Recheck wird vorher ausgelöst.
- `application(_:open:)` im `AppDelegate` empfängt URLs auch bei einer reinen `MenuBarExtra`-App ohne Fenster.
- Die `xcodebuild`-Meldung „Using the first of multiple matching destinations“ ist harmlos.

## Offene Probleme

- Scroll-Grenze der Paketliste (ab 12 Zeilen) ist ungetestet, weil bisher zu wenige Pakete veraltet waren. Risiko gering; prüfen, sobald einmal viele Pakete veraltet sind.
- `.vscode/settings.json` gibt es bewusst nicht: Die Einstellung `swift.searchSubfoldersForPackages` existiert in der installierten Erweiterung nicht (vorhanden ist `swift.ignoreSearchingForPackagesInSubfolders`). Noch zu prüfen: Findet die Erweiterung `Packages/BrewCheck` von selbst (keine roten Fehler in den Quelldateien, Tests in der Seitenleiste)? Falls nicht, passende Einstellung ergänzen.
- `startUpgrade(greedy:)` verwendet bis Phase 6 fest `greedy: true`; die Einstellung dazu kommt in Phase 6.
- Bewusst noch nicht umgesetzt: Scheduler (Schritt 4); stille Wiederholung nach Fehlschlägen mit `showsFailure` (Schritt 5; bis dahin zeigt `AppState` jeden Fehler sofort, `consecutiveFailures` wird gezählt); Mitteilungen (Schritte 6 und 7); „Log öffnen“, Logdatei und Einstellungen (Phase 6).
- Möglicherweise noch gesetzt: `checkInterval` steht auf 180 Sekunden, falls es nach der Handprobe nicht gelöscht wurde. Zurücksetzen mit `defaults delete io.github.muunleit-projects.thetap checkInterval` (App vorher beenden).
- Offene Frage zum Plan: „Jetzt prüfen“ übergeht laut Plan die Bedingung „kein Upgrade läuft“. Klickt der Nutzer während „Upgrade läuft“, läuft `brew update` parallel zu `brew upgrade` im Terminal; ob brew das sperrt, ist nicht geprüft. Entscheidung des Nutzers steht aus (so lassen oder den Knopf während eines Upgrades deaktivieren).
- Signierung im Alltag (Phase 5), Updates mit Ad-hoc-Signierung (Phase 7b) und Standardwerte (nach einer Woche Alltag) sind weiter offen, siehe PLAN.md unter „Offene Punkte“.

## Nächster Schritt

Phase 5, Schritt 4 – Scheduler (`App/Scheduler.swift`) nach „Prüfplan“ in PLAN.md:

- Start: 10 Sekunden nach dem Start `checkIfDue()`.
- Wecker: `NSBackgroundActivityScheduler` mit `repeats = true`, Takt = Prüfintervall durch 3, höchstens 15 Minuten; er ruft nur `checkIfDue()`, die Wiederholung nach Fehlschlägen ergibt sich daraus von selbst.
- Aufwachen: `NSWorkspace.didWakeNotification` über `NSWorkspace.shared.notificationCenter`, danach 60 Sekunden warten und `checkIfDue()`.
- Der `AppDelegate` hält und startet den Scheduler.
- Zu beachten: Ob der `completion`-Handler von `NSBackgroundActivityScheduler` im Swift-6-Modus `Sendable` ist, ist unbekannt. Bei einem Build-Fehler `nonisolated(unsafe)` oder eine andere Lösung mit dem Nutzer klären, nicht raten.
- Handprobe mit `checkInterval` von 3 Minuten (`defaults write io.github.muunleit-projects.thetap checkInterval -float 180`, App vorher beenden), Log mit `log stream` mitlesen. Geprüft werden: Prüfung ohne Zutun nach Ablauf des Intervalls, Prüfung nach dem Aufwachen aus dem Ruhezustand, keine automatische Prüfung während „Upgrade läuft“.

Danach Schritt 5 (stille Wiederholung): `AppState` unterscheidet manuelle und automatische Prüfungen und nutzt `Policies.showsFailure`; „Jetzt prüfen“ setzt `consecutiveFailures` zurück und zeigt Fehler sofort.

Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`, `App/AppState.swift`, `App/AppDelegate.swift`.
