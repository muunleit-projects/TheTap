# TheTap – Status

Stand: 22.10.2026

## Aktuelle Phase

Phase 5 – Automatik und Mitteilungen: Schritte 1 bis 6 von 7 sind fertig, geprüft und gepusht.
Als Nächstes: Schritt 7 (Aktion und Delegate), noch nicht begonnen.

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Letzter Push: `56f4b6a` (Phase 5, Schritt 6). Davor `914f0de` (Schritt 5), `98b8c0c` (vom Nutzer gepusht, Inhalt im Chat nicht genannt) und `8536dbf` (Schritt 4). Commits der Phase 5: `8c568ca` (Schritt 1), `af55f21` (Schritt 2), `56688cb` (Schritt 3), `8536dbf` (Schritt 4), `914f0de` (Schritt 5), `56f4b6a` (Schritt 6). Phase 4 endete mit `64eaa17`.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0. brew liegt unter `/opt/homebrew/bin/brew` (normale Datei, kein Symlink).
- VS Code mit der Swift-Erweiterung (swiftlang) ist installiert.
- CI: `.github/workflows/ci.yml` läuft auf dem Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3, also älter als der Mac. Regeln dazu in PLAN.md unter „Feste Entscheidungen → Toolchain“.
- Die CI führt `swift test`, die Installation von XcodeGen und `scripts/build.sh` ohne `if:`-Bedingungen aus; nichts wird still übersprungen. Letzter Lauf (nach `56f4b6a`) grün.
- Tests: 73 Tests in 6 Suites, lokal (auch mit `HOMEBREW_NO_AUTO_UPDATE=1`) und in der CI grün.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen (GitHub sperrt den automatischen Zugriff auf die Unterordner). Dateien, um die es geht, lädt der Nutzer in den Chat hoch oder kopiert sie hinein.

## Erledigt

- Phase 0: Werkzeuge, Repo, `.gitignore`, `docs/PLAN.md`, `docs/STATUS.md`, `.vscode/` (extensions.json, tasks.json) und CI.
- Phase 1: Package `Packages/BrewCheck` mit Bibliothek `BrewCheck` (Models, BrewLocator, CommandRunner, ProcessRunner, OutdatedParser, BrewChecker, Policies) und Tests. `BrewChecker.init`-Parameter: `runner`, `locator`, `baseEnvironment`, `updateTimeout`, `outdatedTimeout`.
- Phase 2: `BrewCheckError.userMessage` (deutsche Kurztexte, für CLI und App gemeinsam) und die CLI `brewcheck-cli`. Abgenommen.
- Phase 3 (abgenommen): `project.yml`, `scripts/build.sh`, `scripts/run.sh`, `AppState`, `MenuBarLabel`, `PackageListView`, `PanelView`, `TheTapApp` mit `MenuBarExtra` im Stil `.window`.
- Phase 4 (abgenommen): `UpgradeScript` in BrewCheck, `App/UpgradeLauncher.swift`, `AppState` mit `canUpgrade`, `startUpgrade(greedy:)`, `finishUpgrade()`, `recheckAfterUpgrade()`; `AppDelegate` verarbeitet `thetap://recheck` in `application(_:open:)`; Knopf „Alles aktualisieren“ im Panel. Der Zustand „Upgrade läuft“ endet nach 2 Stunden von selbst, falls kein Recheck kommt.
- Phase 5, Schritt 1 (`8c568ca`, abgenommen): `App/NetworkMonitor.swift` (`@MainActor`, `NWPathMonitor`, meldet über `onChange`); `AppDelegate` startet ihn in `applicationDidFinishLaunching`, loggt jede Änderung (Kategorie `scheduler`) und ruft `AppState.networkChanged(isOnline:)`. `AppState.isOnline`; ein Fehlschlag ohne Netz ergibt „Offline“ statt „Fehler“ (`failCheck`).
- Phase 5, Schritt 2 (`af55f21`, abgenommen): In `Policies`: `failuresBeforeError = 3`, `showsFailure(consecutiveFailures:manual:)`, Struktur `NotificationText` und `notificationText(newPackages:badgeCount:)`; 14 neue Tests in `PoliciesTests`. `consecutiveFailures` zählt den aktuellen Fehlschlag mit, ein automatischer Fehler wird also ab dem 3. Fehlschlag in Folge sichtbar.
- Phase 5, Schritt 3 (`56688cb`, abgenommen): `AppState.checkIfDue()` prüft nacheinander: läuft keine Prüfung, läuft kein Upgrade, ist das Netz da (sonst Phase „Offline“), ist `isCheckDue` wahr; jede Entscheidung wird geloggt (Kategorie `scheduler`). `AppState.checkInterval` liest den `UserDefaults`-Schlüssel `checkInterval` bei jedem Zugriff (Standard 21600 s). Ein Recheck, der während einer Prüfung kommt, wird vorgemerkt (`recheckPending`) und läuft direkt danach ohne `brew update`. `networkChanged` nutzt `checkIfDue()`; war nichts fällig, kehrt die Phase zum vorigen Stand zurück (`restorePhase()`).
- Phase 5, Schritt 4 (`8536dbf`, abgenommen): `App/Scheduler.swift` (`@MainActor`, hält `AppState`): Start-Trigger 10 s nach dem Start, `NSBackgroundActivityScheduler` (Takt = `checkInterval / 3`, höchstens 15 Minuten, `tolerance` = Takt / 4, `qualityOfService = .utility`, Kennung `io.github.muunleit-projects.thetap.check`), `NSWorkspace.didWakeNotification` mit 60 s Wartezeit. Jeder Trigger loggt `Trigger: <Grund>` (Kategorie `scheduler`) und ruft nur `AppState.checkIfDue()`. `restartActivity()` legt den Wecker neu an (Phase 6 ruft es nach einer Intervalländerung). Der `AppDelegate` erzeugt und startet den Scheduler in `applicationDidFinishLaunching`. Von Hand per Log geprüft (Intervall 180 s): Start-Trigger, Timer-Ticks, Prüfung nach Intervallablauf, Überspringen bei laufendem Upgrade, Prüfung nach Ruhezustand.
- Phase 5, Schritt 5 (`914f0de`, abgenommen): `AppState.checkNow(runUpdate:manual:)` und `performCheck` unterscheiden manuelle und automatische Prüfungen. „Jetzt prüfen“ (`PanelView`) ist manuell, `checkIfDue()` und der Recheck nach einem Upgrade sind automatisch. Eine manuelle Prüfung setzt `consecutiveFailures` vorher auf 0; `failCheck` zählt den Fehlschlag, `Policies.showsFailure` entscheidet über die Anzeige, ein stiller Fehlschlag ruft `restorePhase()`. „Jetzt prüfen“ ist während eines Upgrades deaktiviert (Entscheidung des Nutzers). Handprobe mit umbenanntem brew (Intervall 180 s): Fehlschlag 1 und 2 still, 3 sichtbar; nach erfolgreicher manueller Prüfung ist der Zähler 0; ein manueller Fehlschlag ist sofort sichtbar (`1 in a row, manual: true, shown: true`).
- Phase 5, Schritt 6 (`56f4b6a`, abgenommen bis auf die offenen Punkte unten): `App/Notifier.swift` (`@MainActor`): `requestAuthorization()` (`[.alert]`), `handle(_:)` nach jeder erfolgreichen Prüfung. `handle` schreibt `notifiedPackages` immer vor dem ersten `await` fort (`newlyOutdated`, `pruneNotified`), sendet nur bei neuen Paketen und erteilter Erlaubnis (`.authorized` oder `.provisional`) eine Mitteilung mit Text aus `notificationText`; Kennung der Mitteilung ist eine `UUID`. `AppState` besitzt `let notifier = Notifier()` und ruft `await notifier.handle(result)` in `performCheck`; der `AppDelegate` fragt die Erlaubnis beim Start an (`Task { await state.notifier.requestAuthorization() }`). Log-Kategorie `notifications`.
- Dokumentation: `PLAN.md` (Phase 5 in 7 Schritten, Phase 7 geteilt in 7a und 7b) und `docs/RELEASE.md` (Release-Anleitung samt `release.yml`) liegen im Repo.

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
- Swift 6: Eine als `nonisolated` markierte Funktion darf nicht auf Konstanten einer `@MainActor`-Klasse zugreifen (Fehler „main actor-isolated static property … can not be referenced from a nonisolated context“).
- Swift 6: Der Block von `NSBackgroundActivityScheduler.schedule` wird in `Scheduler.swift` als `@Sendable [weak self] completion in …` geschrieben; das baut lokal (Swift 6.4) und in der CI (Swift 6.3.3). `completion(.finished)` wird direkt im Block aufgerufen, nur der Aufruf von `trigger` läuft in einer `Task { @MainActor … }`.
- Swift 6: `Notifier` nutzt `UNUserNotificationCenter.current()` als lokale Konstante in den `async`-Methoden und `await center.notificationSettings()`, `await center.add(_:)`; das baut lokal (Swift 6.4) und in der CI (Swift 6.3.3) ohne Fehler.
- `NSBackgroundActivityScheduler` mit Takt 60 s tickte in der Handprobe nach 53 bis 75 s; der erste Tick kam erst nach 108 s. Beim App-Start am 22.10. (Takt 900 s) feuerte der Timer dagegen schon direkt nach dem Start (`Trigger: timer`), vor dem Start-Trigger. Das System verschiebt den Wecker also, in beide Richtungen.
- Nach dem Ruhezustand startete in beiden Handproben schon eine Prüfung, bevor der Wake-Trigger feuerte; der Wake-Trigger fand dann nichts mehr fällig. Welcher Auslöser sie startete, zeigt der Log-Auszug der zweiten Probe nicht (die `Trigger:`-Zeile fehlte). Für die Abnahme war das unerheblich.
- Das Log der App lässt sich im Terminal mitlesen: `log stream --predicate 'subsystem == "io.github.muunleit-projects.thetap"'`. `Logger.notice`-Meldungen erscheinen dort ohne weitere Optionen. Die Zeile `Trigger: …` zeigt, welcher Auslöser eine Entscheidung angestoßen hat. Erfolgreiche Prüfungen loggt `AppState` nicht selbst; sichtbar sind sie nur über die Zeilen der Kategorie `notifications` („No new packages …“, „Notification sent …“).
- Handprobe für Fehlschläge: `mv /opt/homebrew/bin/brew /opt/homebrew/bin/brew.off` macht brew für `BrewLocator` unauffindbar und ergibt „Homebrew nicht gefunden …“; mit `mv /opt/homebrew/bin/brew.off /opt/homebrew/bin/brew` wieder herstellen. Dabei vorher `which -a brew` prüfen (nur ein Treffer).
- Mitteilungen, Handprobe vom 22.10.: Beim ersten Start war die Erlaubnis noch nicht erteilt; die Prüfung loggte `Not sending: notifications are not allowed (1 new)` und schrieb „hello“ trotzdem in `notifiedPackages` (so vorgesehen). Die Erlaubnis-Anfrage lief rund 43 Sekunden und endete mit „Authorization request failed: Notifications are not allowed for this application“. Nach Angabe des Nutzers musste die App nach dem Erteilen der Erlaubnis einmal beendet und neu gestartet werden; danach `Authorization granted`. Wie die Erlaubnis erteilt wurde (Dialog oder Systemeinstellungen) und der Text des Dialogs sind nicht notiert.
- Mitteilungen funktionieren mit der Ad-hoc-Signierung des lokalen Builds: Banner und Eintrag in der Mitteilungszentrale (22.10., Testpaket `hello`, nicht angepinnt). Nach einem Update von `hello` stand `notifiedPackages` bei 0 Einträgen; als `hello` wieder veraltet war, kam erneut genau eine Mitteilung („1 Homebrew-Update verfügbar | hello“).
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
- Offene Abnahmepunkte der Phase 5, siehe PLAN.md: (a) Erlaubnis beim ersten Start: Der Weg (Dialog oder Systemeinstellungen) und der genaue Text sind nicht notiert; der Nutzer nennt ihn im neuen Chat. Wichtig für die README (Phase 7a) und den offenen Punkt „Signierung im Alltag“. Offen ist auch, warum nach dem Erteilen ein Neustart nötig war (`notificationSettings()` wird bei jeder Mitteilung neu gelesen). (b) „Eine weitere Prüfung ohne Änderung ergibt keine Mitteilung“ ist nach einer gesendeten Mitteilung noch nicht im Log gezeigt; einmal „Jetzt prüfen“ klicken, erwartet `No new packages to announce (N known)`. (c) Die Aktion „Alles aktualisieren“ in der Mitteilung (Schritt 7). (d) Erlaubnis nach einem Neubau mit `scripts/run.sh`: mit dem Build von Schritt 7 prüfen, ob die Erlaubnis erhalten bleibt oder die Anfrage erneut erscheint.
- Noch nicht umgesetzt: Aktion, Kategorie und Delegate für Mitteilungen (Schritt 7); „Log öffnen“, Logdatei und Einstellungen (Phase 6). Ohne den Delegaten zeigt macOS Mitteilungen womöglich nicht, solange die App aktiv ist; `willPresent` kommt in Schritt 7.
- Signierung im Alltag (Phase 5), Updates mit Ad-hoc-Signierung (Phase 7b) und Standardwerte (nach einer Woche Alltag) sind weiter offen, siehe PLAN.md unter „Offene Punkte“.

## Nächster Schritt

Phase 5, Schritt 7 – Aktion und Delegate, nach „Mitteilungen (`Notifier`, Phase 5)“ in PLAN.md:

- `AppDelegate` wird `UNUserNotificationCenterDelegate` und setzt sich in `applicationWillFinishLaunching(_:)` als Delegate (Apple verlangt das vor dem Ende des Starts; in der Doku nachprüfen).
- `userNotificationCenter(_:willPresent:)` liefert `[.banner, .list]`.
- Eine `UNNotificationCategory` mit der Aktion „Alles aktualisieren“; `Notifier` setzt die Kategorie bei jeder Mitteilung (`categoryIdentifier`). Die Aktion startet das Upgrade wie der Knopf im Panel (`AppState.startUpgrade()`); ist gerade kein Upgrade möglich, passiert nichts.
- Handprobe: Mitteilung auslösen (ein veraltetes, nicht angepinntes Paket und `defaults delete io.github.muunleit-projects.thetap notifiedPackages` bei beendeter App), Aktion wählen, prüfen, dass das Terminal sich öffnet. Danach die offenen Abnahmepunkte (a) bis (d) abarbeiten.
- Danach Phase 5 abnehmen (alle Kriterien in PLAN.md abhaken, `checkInterval` mit `defaults delete io.github.muunleit-projects.thetap checkInterval` zurücksetzen, falls gesetzt) und Phase 6 beginnen.

Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`, `App/AppState.swift`, `App/AppDelegate.swift`, `App/Notifier.swift`.
