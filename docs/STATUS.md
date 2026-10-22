# TheTap – Status

Stand: 22.10.2026

## Aktuelle Phase

Phase 5 – Automatik und Mitteilungen: abgenommen (alle sieben Schritte, alle Kriterien in PLAN.md abgehakt).
Als Nächstes: Phase 6, Schritt 1 (Logdatei), noch nicht begonnen.

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Letzter Push: `a8c0114` (Phase 5, Schritt 7), CI grün. Commits der Phase 5: `8c568ca` (Schritt 1), `af55f21` (Schritt 2), `56688cb` (Schritt 3), `8536dbf` (Schritt 4), `914f0de` (Schritt 5), `56f4b6a` (Schritt 6), `a8c0114` (Schritt 7); dazwischen `98b8c0c` (vom Nutzer gepusht, Inhalt im Chat nicht genannt) und `32ac370` (PLAN.md und STATUS.md nach Schritt 6). Phase 4 endete mit `64eaa17`.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0. brew liegt unter `/opt/homebrew/bin/brew` (normale Datei, kein Symlink).
- VS Code mit der Swift-Erweiterung (swiftlang) ist installiert.
- CI: `.github/workflows/ci.yml` läuft auf dem Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3, also älter als der Mac. Regeln dazu in PLAN.md unter „Feste Entscheidungen → Toolchain“.
- Die CI führt `swift test`, die Installation von XcodeGen und `scripts/build.sh` ohne `if:`-Bedingungen aus; nichts wird still übersprungen. Letzter Lauf (nach `a8c0114`) grün.
- Tests: 73 Tests in 6 Suites, lokal (auch mit `HOMEBREW_NO_AUTO_UPDATE=1`) und in der CI grün.
- `checkInterval` ist nicht gesetzt (Log am 22.10.: `interval 21600`), es gilt der Standard von 6 Stunden.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen (GitHub sperrt den automatischen Zugriff auf die Unterordner). Dateien, um die es geht, lädt der Nutzer in den Chat hoch oder kopiert sie hinein.

## Erledigt

- Phase 0: Werkzeuge, Repo, `.gitignore`, `docs/PLAN.md`, `docs/STATUS.md`, `.vscode/` (extensions.json, tasks.json) und CI.
- Phase 1: Package `Packages/BrewCheck` mit Bibliothek `BrewCheck` (Models, BrewLocator, CommandRunner, ProcessRunner, OutdatedParser, BrewChecker, Policies) und Tests. `BrewChecker.init`-Parameter: `runner`, `locator`, `baseEnvironment`, `updateTimeout`, `outdatedTimeout`.
- Phase 2: `BrewCheckError.userMessage` (deutsche Kurztexte, für CLI und App gemeinsam) und die CLI `brewcheck-cli`. Abgenommen.
- Phase 3 (abgenommen): `project.yml`, `scripts/build.sh`, `scripts/run.sh`, `AppState`, `MenuBarLabel`, `PackageListView`, `PanelView`, `TheTapApp` mit `MenuBarExtra` im Stil `.window`.
- Phase 4 (abgenommen): `UpgradeScript` in BrewCheck, `App/UpgradeLauncher.swift`, `AppState` mit `canUpgrade`, `startUpgrade(greedy:)`, `finishUpgrade()`, `recheckAfterUpgrade()`; `AppDelegate` verarbeitet `thetap://recheck` in `application(_:open:)`; Knopf „Alles aktualisieren“ im Panel. Der Zustand „Upgrade läuft“ endet nach 2 Stunden von selbst, falls kein Recheck kommt.
- Phase 5 (abgenommen am 22.10.2026):
  - Schritt 1 (`8c568ca`): `App/NetworkMonitor.swift` (`@MainActor`, `NWPathMonitor`, meldet über `onChange`); `AppDelegate` startet ihn in `applicationDidFinishLaunching`, loggt jede Änderung (Kategorie `scheduler`) und ruft `AppState.networkChanged(isOnline:)`. Ein Fehlschlag ohne Netz ergibt „Offline“ statt „Fehler“ (`failCheck`).
  - Schritt 2 (`af55f21`): In `Policies`: `failuresBeforeError = 3`, `showsFailure(consecutiveFailures:manual:)`, Struktur `NotificationText` und `notificationText(newPackages:badgeCount:)`; 14 neue Tests. `consecutiveFailures` zählt den aktuellen Fehlschlag mit, ein automatischer Fehler wird also ab dem 3. Fehlschlag in Folge sichtbar.
  - Schritt 3 (`56688cb`): `AppState.checkIfDue()` prüft nacheinander: läuft keine Prüfung, läuft kein Upgrade, ist das Netz da (sonst Phase „Offline“), ist `isCheckDue` wahr; jede Entscheidung wird geloggt (Kategorie `scheduler`). `AppState.checkInterval` liest den `UserDefaults`-Schlüssel `checkInterval` bei jedem Zugriff (Standard 21600 s). Ein Recheck während einer Prüfung wird vorgemerkt (`recheckPending`) und läuft direkt danach ohne `brew update`. `networkChanged` nutzt `checkIfDue()`; war nichts fällig, kehrt die Phase zum vorigen Stand zurück (`restorePhase()`).
  - Schritt 4 (`8536dbf`): `App/Scheduler.swift` (`@MainActor`, hält `AppState`): Start-Trigger 10 s nach dem Start, `NSBackgroundActivityScheduler` (Takt = `checkInterval / 3`, höchstens 15 Minuten, `tolerance` = Takt / 4, `qualityOfService = .utility`, Kennung `io.github.muunleit-projects.thetap.check`), `NSWorkspace.didWakeNotification` mit 60 s Wartezeit. Jeder Trigger loggt `Trigger: <Grund>` und ruft nur `AppState.checkIfDue()`. `restartActivity()` legt den Wecker neu an (Phase 6 ruft es nach einer Intervalländerung). Der `AppDelegate` erzeugt und startet den Scheduler.
  - Schritt 5 (`914f0de`): `AppState.checkNow(runUpdate:manual:)` und `performCheck` unterscheiden manuelle und automatische Prüfungen. „Jetzt prüfen“ ist manuell, `checkIfDue()` und der Recheck nach einem Upgrade sind automatisch. Eine manuelle Prüfung setzt `consecutiveFailures` vorher auf 0; `failCheck` zählt, `Policies.showsFailure` entscheidet über die Anzeige, ein stiller Fehlschlag ruft `restorePhase()`. „Jetzt prüfen“ ist während eines Upgrades deaktiviert (Entscheidung des Nutzers).
  - Schritt 6 (`56f4b6a`): `App/Notifier.swift` (`@MainActor`): `requestAuthorization()` (`[.alert]`), `handle(_:)` nach jeder erfolgreichen Prüfung. `handle` schreibt `notifiedPackages` immer vor dem ersten `await` fort, sendet nur bei neuen Paketen und erteilter Erlaubnis (`.authorized` oder `.provisional`) eine Mitteilung mit Text aus `notificationText`. `AppState` besitzt `let notifier = Notifier()` und ruft `await notifier.handle(result)` in `performCheck`. Log-Kategorie `notifications`.
  - Schritt 7 (`a8c0114`): `Notifier.registerCategories()` (Kategorie `thetap.updates` mit der Aktion `thetap.upgrade`, Titel „Alles aktualisieren“), `AppDelegate` als `UNUserNotificationCenterDelegate` (Delegate in `applicationWillFinishLaunching`, `willPresent` liefert `[.banner, .list]`, `didReceive` ruft `AppState.startUpgrade()`). Der Code lag schon vor dem Chat im Arbeitsverzeichnis, war aber nicht committet; im Chat geprüft und committet.
  - Handprobe Schritt 7 (22.10., Testpaket `hello`, Log): `Notification category registered`, `Authorization granted`, genau eine Mitteilung (`1 Homebrew-Update verfügbar | hello`), zweite Prüfung `No new packages to announce (1 known)`, Aktion in der Mitteilungszentrale → `Notification action: upgrade (possible: true)`, Terminal-Upgrade, danach `Recheck requested via URL` und `No new packages to announce (0 known)`.
- Dokumentation: `PLAN.md` und `docs/RELEASE.md` (Release-Anleitung samt `release.yml`) liegen im Repo.

## Erkenntnisse

- `brew outdated --json=v2 --greedy` liefert Exit-Code 0, auch wenn Pakete veraltet sind. Exit-Code ungleich 0 ist also ein Fehler; `BrewChecker` parst dann nichts.
- `real.json` enthält nur ein Cask (`losslesscut`) und keine Formulae; Formulae und angepinnte Pakete kommen über selbst geschriebene Fixtures.
- Die GitHub-Runner setzen `HOMEBREW_NO_AUTO_UPDATE=1` selbst. Tests dürfen nie von der Umgebung der Maschine abhängen; `BrewChecker` bekommt `baseEnvironment` als Parameter. Prüfung: `HOMEBREW_NO_AUTO_UPDATE=1 swift test`.
- `PackageKey` = Name + Art + `currentVersion`. Eine neue Version desselben Pakets zählt als neu. Ein in der Zukunft liegender Zeitpunkt der letzten Prüfung gilt als „Prüfung fällig“.
- Die Testausgabe zählt 6 Suites, obwohl es 8 Testdateien gibt: `BrewLocatorTests` und `ModelsTests` haben kein `@Suite`. Das ist harmlos. Die Testausgabe nennt außerdem `Target Platform: arm64e-apple-macos14.0`; das ist nur die Anzeige des Test-Frameworks.
- Ohne Netz scheitert `brew update` mit Exit-Code 1 und „Could not resolve host“. Die App zeigt dann „Offline“ statt des Fehler-Icons, sofern `NWPathMonitor` das Netz als weg meldet.
- `NWPathMonitor` meldet bei einem Wechsel mehrfach (z. B. zweimal „offline“ oder zweimal „online“ kurz nacheinander). Der `AppDelegate` loggt jede Meldung; `AppState.networkChanged` ignoriert eine Meldung ohne Statuswechsel.
- `brew outdated` aktualisiert die Homebrew-API-Daten selbst, wenn `HOMEBREW_NO_AUTO_UPDATE` nicht gesetzt ist. Deshalb zeigt ein Lauf mit `--no-update` ggf. weniger Pakete als ein manueller `brew outdated`.
- Swift 6 erlaubt Top-Level-`await` in `main.swift`; `exit(n)` beendet die CLI mit dem Exit-Code.
- Swift 6: Eine als `nonisolated` markierte Funktion darf nicht auf Konstanten einer `@MainActor`-Klasse zugreifen (Fehler „main actor-isolated static property … can not be referenced from a nonisolated context“). Deshalb sind `categoryIdentifier` und `upgradeActionIdentifier` in `Notifier` `nonisolated static`.
- Swift 6: Der Block von `NSBackgroundActivityScheduler.schedule` wird in `Scheduler.swift` als `@Sendable [weak self] completion in …` geschrieben; das baut lokal (Swift 6.4) und in der CI (Swift 6.3.3). `completion(.finished)` wird direkt im Block aufgerufen, nur der Aufruf von `trigger` läuft in einer `Task { @MainActor … }`.
- Swift 6: `Notifier` nutzt `UNUserNotificationCenter.current()` als lokale Konstante in den `async`-Methoden; die Delegate-Methoden im `AppDelegate` sind `nonisolated async` und springen für die Aktion per `await` auf eine `@MainActor`-Methode; das baut lokal und in der CI ohne Fehler.
- `NSBackgroundActivityScheduler` mit Takt 60 s tickte in der Handprobe nach 53 bis 75 s; der erste Tick kam erst nach 108 s. Bei Takt 900 s feuerte der Timer dagegen schon direkt nach dem App-Start (`Trigger: timer`), vor dem Start-Trigger (zuletzt am 22.10. beim Test von Schritt 7). Das System verschiebt den Wecker also, in beide Richtungen. Der Start-Trigger findet dann nichts mehr fällig (`Skipped: not due yet`), das ist richtig.
- Nach dem Ruhezustand startete in beiden Handproben schon eine Prüfung, bevor der Wake-Trigger feuerte; welcher Auslöser sie startete, zeigt der Log-Auszug der zweiten Probe nicht. Für die Abnahme war das unerheblich.
- Das Log der App lässt sich im Terminal mitlesen: `log stream --predicate 'subsystem == "io.github.muunleit-projects.thetap"'`. `Logger.notice`-Meldungen erscheinen dort ohne weitere Optionen. Erfolgreiche Prüfungen loggt `AppState` nicht selbst; sichtbar sind sie nur über die Zeilen der Kategorie `notifications` („No new packages …“, „Notification sent …“).
- Handprobe für Fehlschläge: `mv /opt/homebrew/bin/brew /opt/homebrew/bin/brew.off` macht brew für `BrewLocator` unauffindbar und ergibt „Homebrew nicht gefunden …“; mit `mv /opt/homebrew/bin/brew.off /opt/homebrew/bin/brew` wieder herstellen. Dabei vorher `which -a brew` prüfen (nur ein Treffer).
- Mitteilungs-Erlaubnis beim ersten Start (Handprobe 22.10.): macOS zeigt ein Banner „Mitteilungen von „TheTap““ („Mitteilungen können Hinweise, Töne und Symbolkennzeichen sein.“, die Knöpfe waren im Screenshot nicht zu sehen). Ein Klick darauf öffnet die Systemeinstellungen (Mitteilungen → TheTap); dort schaltet der Nutzer „Mitteilungen erlauben“ (Schalter oben rechts) ein. Davor loggte die Prüfung `Not sending: notifications are not allowed (1 new)` und schrieb die Pakete trotzdem in `notifiedPackages` (so vorgesehen); die Erlaubnis-Anfrage lief rund 43 Sekunden und endete mit „Authorization request failed: Notifications are not allowed for this application“. Nach Angabe des Nutzers musste die App nach dem Erteilen einmal beendet und neu gestartet werden; danach `Authorization granted`. Warum der Neustart nötig war, ist ungeklärt (`notificationSettings()` wird bei jeder Mitteilung neu gelesen).
- Mitteilungen funktionieren mit der Ad-hoc-Signierung des lokalen Builds, und die Erlaubnis bleibt nach einem Neubau mit `scripts/run.sh` erhalten (22.10.: `Authorization granted` ohne neue Abfrage). Die Aktion „Alles aktualisieren“ erscheint als Knopf in der Mitteilung in der Mitteilungszentrale.
- Nach einem Update von `hello` stand `notifiedPackages` bei 0 Einträgen; als `hello` wieder veraltet war, kam erneut genau eine Mitteilung.
- SF Symbols auf dem Mac des Nutzers bestätigt: `mug`, `mug.fill`, `arrow.triangle.2.circlepath`, `pin`, `exclamationmark.triangle`.
- `brew upgrade` kennt `--no-ask` (kurz `-y`) und `--greedy` (kurz `-g`) in der installierten Homebrew-Version.
- `.command`-Dateien öffnen sich auf dem Mac des Nutzers in der Terminal-App (nicht iTerm).
- Terminal schließt das Fenster, sobald die Shell sauber endet. Deshalb wartet das Upgrade-Skript am Ende mit `read -k 1` auf einen Tastendruck; der Recheck wird vorher ausgelöst.
- `application(_:open:)` im `AppDelegate` empfängt URLs auch bei einer reinen `MenuBarExtra`-App ohne Fenster.
- `scripts/build.sh` baut mit `-derivedDataPath build`; die App liegt danach unter `build/Build/Products/Debug/TheTap.app`. `scripts/run.sh` beendet die laufende Instanz selbst; wer die App von Hand mit `open` startet, muss sie vorher über „Beenden“ schließen.
- Die `xcodebuild`-Meldung „Using the first of multiple matching destinations“ ist harmlos.

## Offene Probleme

- Scroll-Grenze der Paketliste (ab 12 Zeilen) ist ungetestet, weil bisher zu wenige Pakete veraltet waren. Risiko gering; prüfen, sobald einmal viele Pakete veraltet sind.
- `.vscode/settings.json` gibt es bewusst nicht: Die Einstellung `swift.searchSubfoldersForPackages` existiert in der installierten Erweiterung nicht (vorhanden ist `swift.ignoreSearchingForPackagesInSubfolders`). Noch zu prüfen: Findet die Erweiterung `Packages/BrewCheck` von selbst (keine roten Fehler in den Quelldateien, Tests in der Seitenleiste)? Falls nicht, passende Einstellung ergänzen.
- `startUpgrade(greedy:)` verwendet bis Phase 6 fest `greedy: true`; die Einstellung dazu kommt in Phase 6.
- Mitteilungs-Erlaubnis: Warum nach dem ersten Erteilen ein Neustart nötig war, ist ungeklärt; der genaue Wortlaut der Knöpfe im Banner ist nicht notiert. Beides wichtig für die README (Phase 7a); beim nächsten frischen Start einer neuen Kopie (Phase 6/7) beobachten.
- Noch nicht umgesetzt: „Log öffnen“, Logdatei und Einstellungen (Phase 6).
- Offen bleiben in PLAN.md unter „Offene Punkte“: Signierung im Alltag (nur noch Login-Start, Phase 6), Updates mit Ad-hoc-Signierung (Phase 7b) und Standardwerte (nach einer Woche Alltag).

## Nächster Schritt

Phase 6, Schritt 1 – Logdatei, nach „Fehlerbehandlung und Logging“ in PLAN.md:

- Fehlerdetails (Befehl, Exit-Code, die letzten 200 Zeilen Ausgabe) zusätzlich nach `~/Library/Logs/TheTap/thetap.log`; ab 1 MB in `thetap.log.1` umbenennen und neu beginnen; nicht `/tmp`.
- „Log öffnen“ in der Phase „Fehler“ im Panel.
- Offen vor dem Bauen: `AppState.failCheck` bekommt bisher nur die `userMessage`, nicht den Fehler selbst. Die Logdatei braucht die Details aus `BrewCheckError`; wie sie dorthin gelangen, klärt der Schritt.
- Danach Schritt 2 (Einstellungsfenster) und so weiter, siehe Phase 6 in PLAN.md.

Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`, `App/AppState.swift`, `App/Views/PanelView.swift` und die Datei, in der `BrewCheckError` definiert ist (im Package `BrewCheck`), dazu `BrewCheckError+Message.swift`.
