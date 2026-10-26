# TheTap – Status

Stand: 22.10.2026

## Aktuelle Phase

Phase 6 – Einstellungen, Login-Start, Feinschliff: Schritt 1 (Logdatei) abgeschlossen und geprüft.
Als Nächstes: Phase 6, Schritt 2 (Einstellungsfenster), noch nicht begonnen.

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Commits dieses Chats: `3e0a17d` (PLAN.md und STATUS.md nach Phase 5), `5ebc449` (Tests für `logDetails`), `c70a664` (Logdatei, „Log öffnen“), `HASH` (UpgradeLauncher schreibt die Ursache ins Log; letzter Push, CI grün). Phase 5 endete mit `a8c0114`, Phase 4 mit `64eaa17`.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0. brew liegt unter `/opt/homebrew/bin/brew` (normale Datei, kein Symlink).
- VS Code mit der Swift-Erweiterung (swiftlang) ist installiert.
- CI: `.github/workflows/ci.yml` läuft auf dem Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3, also älter als der Mac. Regeln dazu in PLAN.md unter „Feste Entscheidungen → Toolchain“. Die CI führt `swift test`, die Installation von XcodeGen und `scripts/build.sh` ohne `if:`-Bedingungen aus; nichts wird still übersprungen.
- Tests: 78 Tests in 7 Suites, lokal (auch mit `HOMEBREW_NO_AUTO_UPDATE=1`) und in der CI grün.
- `checkInterval` ist nicht gesetzt, es gilt der Standard von 6 Stunden.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen (GitHub sperrt den automatischen Zugriff auf die Unterordner). Dateien, um die es geht, lädt der Nutzer in den Chat hoch oder kopiert sie hinein.

## Erledigt

- Phase 0: Werkzeuge, Repo, `.gitignore`, `docs/PLAN.md`, `docs/STATUS.md`, `.vscode/` (extensions.json, tasks.json) und CI.
- Phase 1: Package `Packages/BrewCheck` mit Bibliothek `BrewCheck` (Models, BrewLocator, CommandRunner, ProcessRunner, OutdatedParser, BrewChecker, Policies) und Tests. `BrewChecker.init`-Parameter: `runner`, `locator`, `baseEnvironment`, `updateTimeout`, `outdatedTimeout`.
- Phase 2: `BrewCheckError.userMessage` (deutsche Kurztexte, für CLI und App gemeinsam) und die CLI `brewcheck-cli`. Abgenommen.
- Phase 3 (abgenommen): `project.yml`, `scripts/build.sh`, `scripts/run.sh`, `AppState`, `MenuBarLabel`, `PackageListView`, `PanelView`, `TheTapApp` mit `MenuBarExtra` im Stil `.window`.
- Phase 4 (abgenommen): `UpgradeScript` in BrewCheck, `App/UpgradeLauncher.swift`, `AppState` mit `canUpgrade`, `startUpgrade(greedy:)`, `finishUpgrade()`, `recheckAfterUpgrade()`; `AppDelegate` verarbeitet `thetap://recheck`; Knopf „Alles aktualisieren“. Der Zustand „Upgrade läuft“ endet nach 2 Stunden von selbst, falls kein Recheck kommt.
- Phase 5 (abgenommen am 22.10.2026), Kurzfassung:
  - Schritt 1 (`8c568ca`): `NetworkMonitor` (`NWPathMonitor`), `AppState.networkChanged(isOnline:)`; ein Fehlschlag ohne Netz ergibt „Offline“.
  - Schritt 2 (`af55f21`): `Policies.failuresBeforeError`, `showsFailure`, `notificationText` samt Tests. `consecutiveFailures` zählt den aktuellen Fehlschlag mit; ein automatischer Fehler wird ab dem 3. Fehlschlag in Folge sichtbar.
  - Schritt 3 (`56688cb`): `AppState.checkIfDue()` mit den vier Bedingungen und Logging (Kategorie `scheduler`); `checkInterval` aus `UserDefaults` (Standard 21600 s); vorgemerkter Recheck (`recheckPending`); `restorePhase()`.
  - Schritt 4 (`8536dbf`): `App/Scheduler.swift` (Start nach 10 s, `NSBackgroundActivityScheduler` mit Takt `checkInterval / 3`, höchstens 15 Minuten, Aufwachen mit 60 s Wartezeit); `restartActivity()` für Phase 6.
  - Schritt 5 (`914f0de`): `checkNow(runUpdate:manual:)`; manuelle und automatische Prüfungen; stille Fehlschläge lassen Liste und Phase stehen. „Jetzt prüfen“ ist während eines Upgrades deaktiviert (Entscheidung des Nutzers).
  - Schritt 6 (`56f4b6a`): `App/Notifier.swift` mit Erlaubnis, `handle(_:)` und Fortschreibung von `notifiedPackages` (immer vor dem ersten `await`).
  - Schritt 7 (`a8c0114`): Kategorie `thetap.updates` mit Aktion `thetap.upgrade`, `AppDelegate` als `UNUserNotificationCenterDelegate`.
- Phase 6, Schritt 1 – Logdatei (abgeschlossen am 22.10.2026):
  - `BrewCheckError.logDetails` in `BrewCheckError+LogDetails.swift` (englischer Logtext mit Befehl, Exit-Code, letzten 200 Zeilen); 5 Tests in `LogDetailsTests.swift` (`5ebc449`).
  - `App/LogFile.swift` (`@MainActor`, `write(_:date:)`): schreibt nach `~/Library/Logs/TheTap/thetap.log`, Zeitstempel ISO 8601 in lokaler Zeit, nach jedem Eintrag eine Leerzeile; ab 1 MB (`maxBytes`) wird die Datei vor dem Schreiben in `thetap.log.1` umbenannt (eine ältere `.1` wird ersetzt). Schreibfehler gehen nur ins Systemlog (Kategorie `check`).
  - `AppState` besitzt `let logFile = LogFile()`. `failCheck(with:details:manual:)` schreibt jeden gezählten Fehlschlag ins Log, auch stille (Kopfzeile `Check failed (N in a row, manual: …, shown: …)`); Offline-Fehlschläge werden nicht geloggt. `fail(with:details:)` (Upgrade-Fehler) schreibt `Upgrade could not be started` plus Details.
  - `PanelView`: Knopf „Log öffnen“ neben „Jetzt prüfen“, nur in der Phase „Fehler“; er öffnet die Datei mit `NSWorkspace.shared.open` (`c70a664`).
  - `UpgradeLaunchError` (in `UpgradeLauncher.swift`) liefert die Ursache über `description`; `AppState` schreibt `"Upgrade launch failed: \(error)"` (`HASH`).
  - Handprobe: brew umbenannt → Panel zeigt „Homebrew nicht gefunden …“ und „Log öffnen“; die Datei öffnet sich in der App „Konsole“; Rotation mit einer 1,1-MB-Datei ergab `thetap.log.1` (1,0 M laut `ls`) und eine neue kleine `thetap.log`.
- Dokumentation: `PLAN.md` und `docs/RELEASE.md` (Release-Anleitung samt `release.yml`) liegen im Repo.

## Erkenntnisse

- `brew outdated --json=v2 --greedy` liefert Exit-Code 0, auch wenn Pakete veraltet sind. Exit-Code ungleich 0 ist also ein Fehler; `BrewChecker` parst dann nichts.
- `real.json` enthält nur ein Cask (`losslesscut`) und keine Formulae; Formulae und angepinnte Pakete kommen über selbst geschriebene Fixtures.
- Die GitHub-Runner setzen `HOMEBREW_NO_AUTO_UPDATE=1` selbst. Tests dürfen nie von der Umgebung der Maschine abhängen; `BrewChecker` bekommt `baseEnvironment` als Parameter. Prüfung: `HOMEBREW_NO_AUTO_UPDATE=1 swift test`.
- `PackageKey` = Name + Art + `currentVersion`. Eine neue Version desselben Pakets zählt als neu. Ein in der Zukunft liegender Zeitpunkt der letzten Prüfung gilt als „Prüfung fällig“.
- Die Testausgabe zählt weniger Suites als Testdateien: `BrewLocatorTests` und `ModelsTests` haben kein `@Suite`. Das ist harmlos. Die Testausgabe nennt außerdem `Target Platform: arm64e-apple-macos14.0`; das ist nur die Anzeige des Test-Frameworks.
- Ohne Netz scheitert `brew update` mit Exit-Code 1 und „Could not resolve host“. Die App zeigt dann „Offline“ statt des Fehler-Icons, sofern `NWPathMonitor` das Netz als weg meldet.
- `NWPathMonitor` meldet bei einem Wechsel mehrfach (z. B. zweimal „offline“ oder zweimal „online“ kurz nacheinander). Der `AppDelegate` loggt jede Meldung; `AppState.networkChanged` ignoriert eine Meldung ohne Statuswechsel.
- `brew outdated` aktualisiert die Homebrew-API-Daten selbst, wenn `HOMEBREW_NO_AUTO_UPDATE` nicht gesetzt ist. Deshalb zeigt ein Lauf mit `--no-update` ggf. weniger Pakete als ein manueller `brew outdated`.
- Swift 6 erlaubt Top-Level-`await` in `main.swift`; `exit(n)` beendet die CLI mit dem Exit-Code.
- Swift 6: Eine als `nonisolated` markierte Funktion darf nicht auf Konstanten einer `@MainActor`-Klasse zugreifen (Fehler „main actor-isolated static property … can not be referenced from a nonisolated context“). Deshalb sind `categoryIdentifier` und `upgradeActionIdentifier` in `Notifier` `nonisolated static`.
- Swift 6: Der Block von `NSBackgroundActivityScheduler.schedule` wird in `Scheduler.swift` als `@Sendable [weak self] completion in …` geschrieben; das baut lokal (Swift 6.4) und in der CI (Swift 6.3.3). `completion(.finished)` wird direkt im Block aufgerufen, nur der Aufruf von `trigger` läuft in einer `Task { @MainActor … }`.
- Swift 6: `Notifier` nutzt `UNUserNotificationCenter.current()` als lokale Konstante in den `async`-Methoden; die Delegate-Methoden im `AppDelegate` sind `nonisolated async` und springen für die Aktion per `await` auf eine `@MainActor`-Methode; das baut lokal und in der CI ohne Fehler.
- `NSBackgroundActivityScheduler` mit Takt 60 s tickte in der Handprobe nach 53 bis 75 s; der erste Tick kam erst nach 108 s. Bei Takt 900 s feuerte der Timer dagegen schon direkt nach dem App-Start (`Trigger: timer`), vor dem Start-Trigger. Das System verschiebt den Wecker also, in beide Richtungen. Der Start-Trigger findet dann nichts mehr fällig (`Skipped: not due yet`), das ist richtig.
- Nach dem Ruhezustand startete in beiden Handproben schon eine Prüfung, bevor der Wake-Trigger feuerte; welcher Auslöser sie startete, zeigt der Log-Auszug der zweiten Probe nicht. Für die Abnahme war das unerheblich.
- Das Systemlog der App lässt sich im Terminal mitlesen: `log stream --predicate 'subsystem == "io.github.muunleit-projects.thetap"'`. `Logger.notice`-Meldungen erscheinen dort ohne weitere Optionen. Erfolgreiche Prüfungen loggt `AppState` nicht selbst; sichtbar sind sie nur über die Zeilen der Kategorie `notifications`.
- Handprobe für Fehlschläge: `mv /opt/homebrew/bin/brew /opt/homebrew/bin/brew.off` macht brew für `BrewLocator` unauffindbar und ergibt „Homebrew nicht gefunden …“; mit `mv /opt/homebrew/bin/brew.off /opt/homebrew/bin/brew` wieder herstellen. Dabei vorher `which -a brew` prüfen (nur ein Treffer). Danach `which brew` muss wieder `/opt/homebrew/bin/brew` zeigen.
- Handprobe für die Rotation: `head -c 1100000 /dev/zero | tr '\0' 'x' > ~/Library/Logs/TheTap/thetap.log`, dann einen Fehler auslösen und `ls -l ~/Library/Logs/TheTap/` ansehen.
- Der Logeintrag zu `brewNotFound` listet alle durchsuchten Ordner, also praktisch den ganzen `PATH` der App mit Pfaden aus dem Home-Verzeichnis. Der Nutzer hat entschieden, das so zu belassen (22.10.2026); relevant nur, falls er das Log je öffentlich teilt.
- Das Log lässt sich über `NSWorkspace.shared.open` öffnen; macOS startet dafür die App „Konsole“ (Handprobe 22.10.2026).
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
- `startUpgrade(greedy:)` verwendet bis Schritt 2 fest `greedy: true`; die Einstellung dazu kommt in Phase 6, Schritt 2.
- Mitteilungs-Erlaubnis: Warum nach dem ersten Erteilen ein Neustart nötig war, ist ungeklärt; der genaue Wortlaut der Knöpfe im Banner ist nicht notiert. Beides wichtig für die README (Phase 7a); beim nächsten frischen Start einer neuen Kopie (Phase 6/7) beobachten.
- Der Fehlerpfad von `UpgradeLauncher` (Skript nicht schreibbar, Terminal nicht zu öffnen) ist nicht von Hand getestet. Bei `cannotOpenScript` steht nur der Pfad im Log, weil `NSWorkspace.open` keinen Grund liefert.
- „Log öffnen“ tut nichts, wenn die Datei nicht existiert (z. B. weil das Schreiben ins Log selbst scheiterte); der Rückgabewert von `NSWorkspace.open` wird nicht ausgewertet.
- Noch nicht umgesetzt: Einstellungen, Installation, Login-Start, App-Icon (Phase 6, Schritte 2 bis 6).
- Offen bleiben in PLAN.md unter „Offene Punkte“: Signierung im Alltag (nur noch Login-Start, Phase 6), Updates mit Ad-hoc-Signierung (Phase 7b) und Standardwerte (nach einer Woche Alltag).

## Nächster Schritt

Phase 6, Schritt 2 – Einstellungsfenster, nach „Einstellungen (Phase 6)“ in PLAN.md:

- `Settings`-Szene in `TheTapApp`, `SettingsLink` im Panel, Fenster kommt nach vorne (`NSApp.activate()`).
- Prüfintervall (1, 3, 6, 12, 24 Stunden; Schlüssel `checkInterval` in Sekunden); eine Änderung wirkt ohne Neustart, indem der Scheduler `restartActivity()` aufruft.
- Mitteilungen senden (an/aus); `Notifier.handle` schreibt `notifiedPackages` auch bei „aus“ fort. Sind sie in den Systemeinstellungen verboten, Hinweis mit Knopf dorthin.
- Casks mit eigenem Updater einbeziehen (`--greedy`), Standard an; gilt für Prüfung und Upgrade (`BrewChecker.outdated(greedy:)`, `startUpgrade(greedy:)`).
- „Log im Finder zeigen“.
- Offen vor dem Bauen: Wie der Scheduler von der Intervalländerung erfährt (der `AppDelegate` hält ihn), klärt der Schritt.

Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`, `App/TheTapApp.swift`, `App/AppState.swift`, `App/AppDelegate.swift`, `App/Scheduler.swift`, `App/Notifier.swift`, `App/Views/PanelView.swift` und `project.yml`.
