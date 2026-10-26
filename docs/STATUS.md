# TheTap – Status

Stand: 26.10.2026

## Aktuelle Phase

Phase 6 – Einstellungen, Login-Start, Feinschliff: Schritt 1 (Logdatei), Schritt 2 (Einstellungsfenster), Schritt 3 (Installation) und Schritt 4 (Beim Anmelden starten) abgeschlossen und geprüft.
Als Nächstes: Phase 6, Schritt 5 (App-Icon), noch nicht begonnen. Vor dem Start klärt die KI mit dem Nutzer, woher das Bild (1024 × 1024 Pixel) kommt.

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Commits der letzten Chats: `3e0a17d` (PLAN.md und STATUS.md nach Phase 5), `5ebc449` (Tests für `logDetails`), `c70a664` (Logdatei, „Log öffnen“), `62c7d35` (UpgradeLauncher schreibt die Ursache ins Log), `9274101` (Plan und Status nach Phase 6, Schritt 1), `ff90382` (Einstellungsfenster), `629dec9` (Plan und Status nach Phase 6, Schritt 2), `5c5661c` (`scripts/install.sh`), `af00b9a` (Push vor Schritt 4), `7de6bf9` (Stand des letzten Push nach Schritt 4, CI grün). Phase 5 endete mit `a8c0114`, Phase 4 mit `64eaa17`.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0. brew liegt unter `/opt/homebrew/bin/brew` (normale Datei, kein Symlink).
- VS Code mit der Swift-Erweiterung (swiftlang) ist installiert.
- CI: `.github/workflows/ci.yml` läuft auf dem Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3, also älter als der Mac. Regeln dazu in PLAN.md unter „Feste Entscheidungen → Toolchain“. Die CI führt `swift test`, die Installation von XcodeGen und `scripts/build.sh` (ohne Parameter, also Debug) ohne `if:`-Bedingungen aus; nichts wird still übersprungen. Für `7de6bf9` ist sie grün.
- Tests: 78 Tests in 7 Suites, lokal (auch mit `HOMEBREW_NO_AUTO_UPDATE=1`) und in der CI grün (Schritte 3 und 4 ändern das Package nicht).
- `checkInterval` ist nicht gesetzt, es gilt der Standard von 6 Stunden (oder der Wert, den der Nutzer im Einstellungsfenster zuletzt gewählt hat).
- Im Alltag läuft die Kopie unter `/Applications/TheTap.app` (installiert mit `scripts/install.sh`); „Beim Anmelden starten“ ist eingeschaltet.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen (GitHub sperrt den automatischen Zugriff auf die Unterordner). Dateien, um die es geht, lädt der Nutzer in den Chat hoch oder kopiert sie hinein.

## Erledigt

- Phase 0: Werkzeuge, Repo, `.gitignore`, `docs/PLAN.md`, `docs/STATUS.md`, `.vscode/` (extensions.json, tasks.json) und CI.
- Phase 1: Package `Packages/BrewCheck` mit Bibliothek `BrewCheck` (Models, BrewLocator, CommandRunner, ProcessRunner, OutdatedParser, BrewChecker, Policies) und Tests. `BrewChecker.init`-Parameter: `runner`, `locator`, `baseEnvironment`, `updateTimeout`, `outdatedTimeout`.
- Phase 2: `BrewCheckError.userMessage` (deutsche Kurztexte, für CLI und App gemeinsam) und die CLI `brewcheck-cli`. Abgenommen.
- Phase 3 (abgenommen): `project.yml`, `scripts/build.sh`, `scripts/run.sh`, `AppState`, `MenuBarLabel`, `PackageListView`, `PanelView`, `TheTapApp` mit `MenuBarExtra` im Stil `.window`.
- Phase 4 (abgenommen): `UpgradeScript` in BrewCheck, `App/UpgradeLauncher.swift`, `AppState` mit `canUpgrade`, `startUpgrade()`, `finishUpgrade()`, `recheckAfterUpgrade()`; `AppDelegate` verarbeitet `thetap://recheck`; Knopf „Alles aktualisieren“. Der Zustand „Upgrade läuft“ endet nach 2 Stunden von selbst, falls kein Recheck kommt.
- Phase 5 (abgenommen am 22.10.2026), Kurzfassung:
  - Schritt 1 (`8c568ca`): `NetworkMonitor` (`NWPathMonitor`), `AppState.networkChanged(isOnline:)`; ein Fehlschlag ohne Netz ergibt „Offline“.
  - Schritt 2 (`af55f21`): `Policies.failuresBeforeError`, `showsFailure`, `notificationText` samt Tests. `consecutiveFailures` zählt den aktuellen Fehlschlag mit; ein automatischer Fehler wird ab dem 3. Fehlschlag in Folge sichtbar.
  - Schritt 3 (`56688cb`): `AppState.checkIfDue()` mit den vier Bedingungen und Logging (Kategorie `scheduler`); `checkInterval` aus `UserDefaults` (Standard 21600 s); vorgemerkter Recheck (`recheckPending`); `restorePhase()`.
  - Schritt 4 (`8536dbf`): `App/Scheduler.swift` (Start nach 10 s, `NSBackgroundActivityScheduler` mit Takt `checkInterval / 3`, höchstens 15 Minuten, Aufwachen mit 60 s Wartezeit); `restartActivity()`.
  - Schritt 5 (`914f0de`): `checkNow(runUpdate:manual:)`; manuelle und automatische Prüfungen; stille Fehlschläge lassen Liste und Phase stehen. „Jetzt prüfen“ ist während eines Upgrades deaktiviert (Entscheidung des Nutzers).
  - Schritt 6 (`56f4b6a`): `App/Notifier.swift` mit Erlaubnis, `handle(_:)` und Fortschreibung von `notifiedPackages` (immer vor dem ersten `await`).
  - Schritt 7 (`a8c0114`): Kategorie `thetap.updates` mit Aktion `thetap.upgrade`, `AppDelegate` als `UNUserNotificationCenterDelegate`.
- Phase 6, Schritt 1 – Logdatei (abgeschlossen am 22.10.2026):
  - `BrewCheckError.logDetails` in `BrewCheckError+LogDetails.swift` (englischer Logtext mit Befehl, Exit-Code, letzten 200 Zeilen); 5 Tests in `LogDetailsTests.swift` (`5ebc449`).
  - `App/LogFile.swift` (`@MainActor`, `write(_:date:)`): schreibt nach `~/Library/Logs/TheTap/thetap.log`, Zeitstempel ISO 8601 in lokaler Zeit, nach jedem Eintrag eine Leerzeile; ab 1 MB (`maxBytes`) wird die Datei vor dem Schreiben in `thetap.log.1` umbenannt (eine ältere `.1` wird ersetzt). Schreibfehler gehen nur ins Systemlog (Kategorie `check`).
  - `AppState` besitzt `let logFile = LogFile()`. `failCheck(with:details:manual:)` schreibt jeden gezählten Fehlschlag ins Log, auch stille (Kopfzeile `Check failed (N in a row, manual: …, shown: …)`); Offline-Fehlschläge werden nicht geloggt. `fail(with:details:)` (Upgrade-Fehler) schreibt `Upgrade could not be started` plus Details.
  - `PanelView`: Knopf „Log öffnen“ neben „Jetzt prüfen“, nur in der Phase „Fehler“; er öffnet die Datei mit `NSWorkspace.shared.open` (`c70a664`).
  - `UpgradeLaunchError` (in `UpgradeLauncher.swift`) liefert die Ursache über `description`; `AppState` schreibt `"Upgrade launch failed: \(error)"` (`62c7d35`).
  - Handprobe: brew umbenannt → Panel zeigt „Homebrew nicht gefunden …“ und „Log öffnen“; die Datei öffnet sich in der App „Konsole“; Rotation mit einer 1,1-MB-Datei ergab `thetap.log.1` (1,0 M laut `ls`) und eine neue kleine `thetap.log`.
- Phase 6, Schritt 2 – Einstellungsfenster (abgeschlossen am 26.10.2026, `ff90382`):
  - Neue Datei `App/Views/SettingsView.swift` (`Form` mit `.formStyle(.grouped)`, Breite 460): Auswahl „Prüfintervall“ (1, 3, 6, 12, 24 Stunden; 6 Stunden als „Standard“ beschriftet), Schalter „Casks mit eigenem Updater einbeziehen“, Schalter „Mitteilungen senden“, Hinweis mit Knopf „Systemeinstellungen öffnen“ (nur wenn macOS Mitteilungen nicht erlaubt), Knopf „Log im Finder zeigen“. Werte über `@AppStorage`.
  - Schlüssel in `UserDefaults`: `checkInterval` (Sekunden), `includeGreedy` (Standard an), `notificationsEnabled` (Standard an). Die statischen Schlüssel in `AppState` und `Notifier` sind `nonisolated`, damit `@AppStorage` sie in Swift 6 lesen darf.
  - `TheTapApp` hat eine `Settings`-Szene; `PanelView` zeigt `SettingsLink` („Einstellungen …“) neben „Beenden“ in einer eigenen Zeile. Das Fenster ruft in `onAppear` `NSApp.activate()` auf.
  - Intervalländerung: `AppState.checkIntervalChanged()` ruft den Rückruf `onCheckIntervalChange`; der `AppDelegate` setzt ihn nach dem Start des Schedulers auf `scheduler.restartActivity()`.
  - `AppState.includeGreedy` (liest `UserDefaults` bei jedem Zugriff) steuert `checker.outdated(runUpdate:greedy:)` und `UpgradeLauncher.start(greedy:)`. `startUpgrade(greedy:)` heißt jetzt `startUpgrade()`.
  - `Notifier.isEnabled`, `Notifier.isAllowedBySystem()`; `handle` schreibt `notifiedPackages` auch bei ausgeschalteten Mitteilungen fort und loggt dann `Not sending: notifications are switched off in the settings`.
  - Handprobe: Das Fenster öffnet sich im Vordergrund, das Panel bleibt dabei offen; jede Intervalländerung erzeugte `Check interval changed to … s` und `Timer set: tick every 900 s` im Log; alle Werte blieben nach einem Neustart erhalten; mit ausgeschalteten Mitteilungen kam keine Mitteilung (17 neue Pakete nach dem Löschen von `notifiedPackages`); „Log im Finder zeigen“ markiert die Datei; bei verbotenen Mitteilungen erscheinen Hinweis und Knopf, und der Knopf öffnet die Seite „Mitteilungen“ der Systemeinstellungen. Mit eingeschaltetem „Casks …“ zeigt die Liste ein Paket mehr als ohne.
- Phase 6, Schritt 3 – Installation (abgeschlossen am 26.10.2026, Push `5c5661c`):
  - `scripts/build.sh` nimmt als ersten Parameter die Konfiguration (`Debug` oder `Release`, Standard `Debug`); weitere Parameter gehen unverändert an `xcodebuild`. Ohne Parameter verhält es sich wie vorher (die CI ist unverändert).
  - Neu: `scripts/install.sh`: `scripts/build.sh Release ONLY_ACTIVE_ARCH=YES` (nur die Architektur dieses Macs), laufende TheTap beenden (SIGTERM, bis 5 s warten), alte Kopie in `/Applications` löschen, neue mit `ditto` aus `build/Build/Products/Release/TheTap.app` kopieren, `codesign --verify --deep --strict`, App starten.
  - Handprobe: `build.sh` ohne Parameter und `install.sh` ergaben `** BUILD SUCCEEDED **`; `pgrep -fl TheTap` zeigt den Pfad unter `/Applications/TheTap.app/Contents/MacOS/`; `codesign -dv`: `Identifier=io.github.muunleit-projects.thetap`, `Signature=adhoc`, `TeamIdentifier=not set`; `lipo -archs`: `arm64`. Die Mitteilungs-Erlaubnis blieb erhalten; ein zweiter Lauf von `install.sh` (Ersetzen einer vorhandenen Kopie) lief ohne Fehler.
- Phase 6, Schritt 4 – Beim Anmelden starten (abgeschlossen am 26.10.2026, Push `7de6bf9`, CI grün):
  - Nur `App/Views/SettingsView.swift` geändert (`import ServiceManagement`): neuer Abschnitt „Start“ ganz oben mit dem Schalter „Beim Anmelden starten“. Der Schalter ist über eine eigene `Binding` an, wenn `SMAppService.mainApp.status` `.enabled` oder `.requiresApproval` ist; Umschalten ruft `register()` bzw. `unregister()`.
  - Bei `.requiresApproval` erscheinen ein Hinweis und der Knopf „Anmeldeobjekte öffnen“ (`SMAppService.openSystemSettingsLoginItems()`); bei `.notFound` ein Hinweis. Fehler von `register()`/`unregister()` erscheinen als rote deutsche Zeile im Fenster und im Systemlog.
  - Der Status wird bei `onAppear` und bei jedem Aktivwerden der App neu gelesen.
  - Neue Log-Kategorie `settings` (Subsystem wie sonst): `Launch at login registered` / `unregistered`, `Login item status: …`, `Launch at login failed: …`.
  - Handprobe (Kopie in `/Applications`): Beim Einschalten zeigte macOS das Banner „Anmeldeobjekt hinzugefügt – „TheTap“ wird bei der Anmeldung automatisch geöffnet …“; unter Systemeinstellungen → Allgemein → Anmeldeobjekte & Erweiterungen steht „TheTap“ in der Liste „Bei der Anmeldung öffnen“; das Log zeigte `Login item status: SMAppServiceStatus(rawValue: 1)`. Nach Ab- und Anmelden lief TheTap von selbst (neue PID, genau eine Instanz unter `/Applications`), das Log zeigte `Trigger: startup`, `Starting check`, `Authorization granted` ohne neue Abfrage.
- Dokumentation: `PLAN.md` und `docs/RELEASE.md` (Release-Anleitung samt `release.yml`) liegen im Repo. `.github/workflows/release.yml` selbst gibt es noch nicht (Phase 7a).

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
- Swift 6: Eine als `nonisolated` markierte Funktion darf nicht auf Konstanten einer `@MainActor`-Klasse zugreifen (Fehler „main actor-isolated static property … can not be referenced from a nonisolated context“). Deshalb sind `categoryIdentifier`, `upgradeActionIdentifier` und `enabledKey` in `Notifier` sowie `checkIntervalKey`, `includeGreedyKey` und `defaultCheckInterval` in `AppState` `nonisolated static`.
- Swift 6: Der Block von `NSBackgroundActivityScheduler.schedule` wird in `Scheduler.swift` als `@Sendable [weak self] completion in …` geschrieben; das baut lokal (Swift 6.4) und in der CI (Swift 6.3.3). `completion(.finished)` wird direkt im Block aufgerufen, nur der Aufruf von `trigger` läuft in einer `Task { @MainActor … }`.
- Swift 6: `Notifier` nutzt `UNUserNotificationCenter.current()` als lokale Konstante in den `async`-Methoden; die Delegate-Methoden im `AppDelegate` sind `nonisolated async` und springen für die Aktion per `await` auf eine `@MainActor`-Methode; das baut lokal und in der CI ohne Fehler.
- `NSBackgroundActivityScheduler` mit Takt 60 s tickte in der Handprobe nach 53 bis 75 s; der erste Tick kam erst nach 108 s. Bei Takt 900 s feuerte der Timer dagegen schon direkt nach dem App-Start (`Trigger: timer`), vor dem Start-Trigger. Das System verschiebt den Wecker also, in beide Richtungen. Der Start-Trigger findet dann nichts mehr fällig (`Skipped: not due yet`), das ist richtig.
- Nach dem Ruhezustand startete in beiden Handproben schon eine Prüfung, bevor der Wake-Trigger feuerte; welcher Auslöser sie startete, zeigt der Log-Auszug der zweiten Probe nicht. Für die Abnahme war das unerheblich.
- Der Takt des Weckers ist `min(Intervall / 3, 900 s)`: Schon bei 1 Stunde Prüfintervall (1200 s) greift die Grenze von 900 s, in der Handprobe zeigte das Log für 1, 3, 12 und 24 Stunden jeweils 900 s.
- Das Systemlog der App lässt sich im Terminal mitlesen: `log stream --predicate 'subsystem == "io.github.muunleit-projects.thetap"'`; rückwirkend mit `log show --last 5m --predicate …`. `Logger.notice`-Meldungen erscheinen dort ohne weitere Optionen. Erfolgreiche Prüfungen loggt `AppState` nicht selbst; sichtbar sind sie nur über die Zeilen der Kategorie `notifications`.
- Handprobe für Fehlschläge: `mv /opt/homebrew/bin/brew /opt/homebrew/bin/brew.off` macht brew für `BrewLocator` unauffindbar und ergibt „Homebrew nicht gefunden …“; mit `mv /opt/homebrew/bin/brew.off /opt/homebrew/bin/brew` wieder herstellen. Dabei vorher `which -a brew` prüfen (nur ein Treffer). Danach `which brew` muss wieder `/opt/homebrew/bin/brew` zeigen.
- Handprobe für die Rotation: `head -c 1100000 /dev/zero | tr '\0' 'x' > ~/Library/Logs/TheTap/thetap.log`, dann einen Fehler auslösen und `ls -l ~/Library/Logs/TheTap/` ansehen.
- Der Logeintrag zu `brewNotFound` listet alle durchsuchten Ordner, also praktisch den ganzen `PATH` der App mit Pfaden aus dem Home-Verzeichnis. Der Nutzer hat entschieden, das so zu belassen (22.10.2026); relevant nur, falls er das Log je öffentlich teilt.
- Das Log lässt sich über `NSWorkspace.shared.open` öffnen; macOS startet dafür die App „Konsole“ (Handprobe 22.10.2026).
- Ein `Settings`-Fenster kommt in der `MenuBarExtra`-App ohne Dock-Icon mit `NSApp.activate()` in `onAppear` nach vorne (Handprobe 26.10.2026); das Panel schließt sich dabei nicht.
- Die URL `x-apple.systempreferences:com.apple.Notifications-Settings.extension` öffnet unter macOS 26 die Seite „Mitteilungen“ der Systemeinstellungen (Handprobe 26.10.2026). Der Code fällt auf `x-apple.systempreferences:` zurück, falls `open` `false` liefert; dieser Rückfall ist nicht getestet.
- Login-Start mit Ad-hoc-Signierung funktioniert für die Kopie in `/Applications` (Handprobe 26.10.2026, nach Ab- und Anmelden). Beobachtet: Bei aktivem Login-Item liefert `SMAppService.mainApp.status` im Log `rawValue: 1`; das passt zu `.enabled` (Banner und Eintrag in den Anmeldeobjekten bestätigen es). In den Systemeinstellungen zeigt TheTap derzeit ein graues Platzhalter-Icon (kein App-Icon vorhanden, siehe Schritt 5).
- Mitteilungs-Erlaubnis beim ersten Start (Handprobe 22.10.): macOS zeigt ein Banner „Mitteilungen von „TheTap““ („Mitteilungen können Hinweise, Töne und Symbolkennzeichen sein.“, die Knöpfe waren im Screenshot nicht zu sehen). Ein Klick darauf öffnet die Systemeinstellungen (Mitteilungen → TheTap); dort schaltet der Nutzer „Mitteilungen erlauben“ (Schalter oben rechts) ein. Davor loggte die Prüfung `Not sending: notifications are not allowed (1 new)` und schrieb die Pakete trotzdem in `notifiedPackages` (so vorgesehen); die Erlaubnis-Anfrage lief rund 43 Sekunden und endete mit „Authorization request failed: Notifications are not allowed for this application“. Nach Angabe des Nutzers musste die App nach dem Erteilen einmal beendet und neu gestartet werden; danach `Authorization granted`. Warum der Neustart nötig war, ist ungeklärt (`notificationSettings()` wird bei jeder Mitteilung neu gelesen).
- Mitteilungen funktionieren mit der Ad-hoc-Signierung des lokalen Builds, und die Erlaubnis bleibt nach einem Neubau mit `scripts/run.sh` erhalten (22.10.: `Authorization granted` ohne neue Abfrage). Das gilt nach Angabe des Nutzers auch für die Release-Kopie in `/Applications` nach `scripts/install.sh` (26.10.2026). Die Aktion „Alles aktualisieren“ erscheint als Knopf in der Mitteilung in der Mitteilungszentrale.
- Nach einem Update von `hello` stand `notifiedPackages` bei 0 Einträgen; als `hello` wieder veraltet war, kam erneut genau eine Mitteilung.
- SF Symbols auf dem Mac des Nutzers bestätigt: `mug`, `mug.fill`, `arrow.triangle.2.circlepath`, `pin`, `exclamationmark.triangle`.
- `brew upgrade` kennt `--no-ask` (kurz `-y`) und `--greedy` (kurz `-g`) in der installierten Homebrew-Version.
- `.command`-Dateien öffnen sich auf dem Mac des Nutzers in der Terminal-App (nicht iTerm).
- Terminal schließt das Fenster, sobald die Shell sauber endet. Deshalb wartet das Upgrade-Skript am Ende mit `read -k 1` auf einen Tastendruck; der Recheck wird vorher ausgelöst.
- `application(_:open:)` im `AppDelegate` empfängt URLs auch bei einer reinen `MenuBarExtra`-App ohne Fenster.
- `scripts/build.sh` baut mit `-derivedDataPath build`; Debug liegt unter `build/Build/Products/Debug/TheTap.app`, Release (`install.sh`) unter `build/Build/Products/Release/TheTap.app`. `scripts/run.sh` beendet die laufende Instanz selbst (auch die Kopie aus `/Applications`) und startet den Debug-Build; danach startet der Nutzer die installierte Kopie mit `open /Applications/TheTap.app`. Wer die App von Hand mit `open` startet, muss sie vorher über „Beenden“ schließen.
- `install.sh` baut mit `ONLY_ACTIVE_ARCH=YES`: Die installierte Kopie enthält nur `arm64`. Universal-Builds (Apple Silicon und Intel) entstehen erst in Phase 7a auf dem Runner.
- Die `xcodebuild`-Meldung „Using the first of multiple matching destinations“ ist harmlos.

## Offene Probleme

- Warnungen im Release-Build wurden nicht ausgewertet (gemeldet wurde nur `** BUILD SUCCEEDED **`). Bei Bedarf: `scripts/build.sh Release ONLY_ACTIVE_ARCH=YES 2>&1 | grep -i warning`.
- Scroll-Grenze der Paketliste (ab 12 Zeilen) ist ungetestet, weil bisher zu wenige Pakete veraltet waren. Risiko gering; prüfen, sobald einmal viele Pakete veraltet sind (am 26.10. waren 17 Pakete neu veraltet; falls die Liste dabei gesehen wurde, hier nachtragen).
- `.vscode/settings.json` gibt es bewusst nicht: Die Einstellung `swift.searchSubfoldersForPackages` existiert in der installierten Erweiterung nicht (vorhanden ist `swift.ignoreSearchingForPackagesInSubfolders`). Noch zu prüfen: Findet die Erweiterung `Packages/BrewCheck` von selbst (keine roten Fehler in den Quelldateien, Tests in der Seitenleiste)? Falls nicht, passende Einstellung ergänzen.
- Mitteilungs-Erlaubnis: Warum nach dem ersten Erteilen ein Neustart nötig war, ist ungeklärt; der genaue Wortlaut der Knöpfe im Banner ist nicht notiert. Beides wichtig für die README (Phase 7a); beim nächsten frischen Start einer neuen Kopie (Phase 7) beobachten.
- Der Fehlerpfad von `UpgradeLauncher` (Skript nicht schreibbar, Terminal nicht zu öffnen) ist nicht von Hand getestet. Bei `cannotOpenScript` steht nur der Pfad im Log, weil `NSWorkspace.open` keinen Grund liefert.
- „Log öffnen“ tut nichts, wenn die Datei nicht existiert (z. B. weil das Schreiben ins Log selbst scheiterte); der Rückgabewert von `NSWorkspace.open` wird nicht ausgewertet.
- Steht in `checkInterval` ein Wert außerhalb der Auswahl (z. B. 180 von Testläufen), zeigt das Auswahlfeld im Einstellungsfenster keinen Eintrag an; die App nutzt den Wert trotzdem. Nach Tests mit `defaults delete io.github.muunleit-projects.thetap checkInterval` zurücksetzen.
- Eine geänderte Einstellung „Casks mit eigenem Updater“ wirkt erst ab der nächsten Prüfung; die angezeigte Liste bleibt bis dahin unverändert.
- `install.sh` setzt Schreibrechte in `/Applications` voraus; beim Nutzer ging es ohne Fehler.
- Der Fehlerpfad des Login-Start-Schalters (`register()` oder `unregister()` wirft) und der Zustand `.requiresApproval` sind nicht von Hand getestet; der Nutzer sah bei `register()` direkt `.enabled`. Der Fall „Schalter in den Systemeinstellungen ausgeschaltet, Fenster zeigt neuen Stand“ wurde nicht gemeldet.
- Noch nicht umgesetzt: App-Icon (Phase 6, Schritt 5) und die Woche Alltag (Schritt 6).
- Offen bleiben in PLAN.md unter „Offene Punkte“: Updates mit Ad-hoc-Signierung (Phase 7b) und Standardwerte (nach einer Woche Alltag). „Signierung im Alltag“ ist geklärt: Login-Start geht mit Ad-hoc-Signierung.

## Nächster Schritt

Phase 6, Schritt 5 – App-Icon, nach PLAN.md:

- Zuerst mit dem Nutzer klären, woher das Bild (1024 × 1024 Pixel) kommt (selbst gestaltet, aus einem Programm, erzeugt?).
- Ein Skript erzeugt daraus mit `sips` die Größen für `App/Assets.xcassets/AppIcon.appiconset`; `project.yml` setzt `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`.
- Vorher prüfen, ob macOS 26 ein solches Icon-Set noch richtig darstellt (nicht raten, nachprüfen). Apples Icon Composer wäre eine eigene App und damit eine Ausnahme von der VS-Code-Regel.
- Danach prüfen: Icon im Finder, in Mitteilungen und in den Anmeldeobjekten (dort zeigt TheTap bisher ein graues Platzhalter-Icon).

Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`, `project.yml`.
