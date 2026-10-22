# TheTap – Status

Stand: 22.10.2026

## Aktuelle Phase

Phase 5 – Automatik und Mitteilungen: Schritte 1 bis 4 von 7 sind fertig, geprüft und gepusht.
Als Nächstes: Schritt 5 (stille Wiederholung), noch nicht begonnen.

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Letzter Push: `8536dbf` (enthält Phase 5, Schritt 4). Davor `b6bd18c` (vom Nutzer gepusht, Inhalt im Chat nicht genannt) und `6dfdfcd` (nur `PLAN.md` und `RELEASE.md`). Commits der Phase 5: `8c568ca` (Schritt 1), `af55f21` (Schritt 2), `56688cb` (Schritt 3), Schritt 4 im Push bis `8536dbf`. Phase 4 endete mit `64eaa17`.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0.
- VS Code mit der Swift-Erweiterung (swiftlang) ist installiert.
- CI: `.github/workflows/ci.yml` läuft auf dem Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3, also älter als der Mac. Regeln dazu in PLAN.md unter „Feste Entscheidungen → Toolchain“.
- Die CI führt `swift test`, die Installation von XcodeGen und `scripts/build.sh` ohne `if:`-Bedingungen aus; nichts wird still übersprungen. Letzter Lauf (nach `8536dbf`) grün.
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
- Phase 5, Schritt 4 (Push `8536dbf`, abgenommen): `App/Scheduler.swift` (`@MainActor`, hält `AppState`): Start-Trigger 10 s nach dem Start, `NSBackgroundActivityScheduler` (Takt = `checkInterval / 3`, höchstens 15 Minuten, `tolerance` = Takt / 4, `qualityOfService = .utility`, Kennung `io.github.muunleit-projects.thetap.check`), `NSWorkspace.didWakeNotification` mit 60 s Wartezeit. Jeder Trigger loggt `Trigger: <Grund>` (Kategorie `scheduler`) und ruft nur `AppState.checkIfDue()`. `restartActivity()` legt den Wecker neu an (Phase 6 ruft es nach einer Intervalländerung). Der `AppDelegate` erzeugt und startet den Scheduler in `applicationDidFinishLaunching`.
  - Von Hand geprüft per Log (Intervall 180 s): Start-Trigger nach 10 s; Timer-Ticks etwa jede Minute, dazwischen „Skipped: not due yet“, nach Ablauf des Intervalls „Starting check“; bei laufendem Upgrade „Skipped: an upgrade is running“; nach 5 Minuten Ruhezustand startete eine Prüfung direkt nach dem Aufwachen, der Wake-Trigger feuerte 61 s nach der Zeile „Mac woke up“. Damit sind die Abnahmekriterien 3 bis 5 der Phase 5 erfüllt.
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
- `NSBackgroundActivityScheduler` mit Takt 60 s tickte in der Handprobe nach 53 bis 75 s; der erste Tick kam erst nach 108 s. Das System verschiebt den Wecker also tatsächlich.
- Nach dem Ruhezustand startete in beiden Handproben schon eine Prüfung, bevor der Wake-Trigger feuerte; der Wake-Trigger fand dann nichts mehr fällig. Welcher Auslöser sie startete, zeigt der Log-Auszug der zweiten Probe nicht (die `Trigger:`-Zeile fehlte). Für die Abnahme war das unerheblich.
- Das Log der App lässt sich im Terminal mitlesen: `log stream --predicate 'subsystem == "io.github.muunleit-projects.thetap"'`. `Logger.notice`-Meldungen erscheinen dort ohne weitere Optionen. Die Zeile `Trigger: …` zeigt, welcher Auslöser eine Entscheidung angestoßen hat.
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
- Bewusst noch nicht umgesetzt: stille Wiederholung nach Fehlschlägen mit `showsFailure` (Schritt 5; bis dahin zeigt `AppState` jeden Fehler sofort, `consecutiveFailures` wird gezählt); Mitteilungen (Schritte 6 und 7); „Log öffnen“, Logdatei und Einstellungen (Phase 6).
- Möglicherweise noch gesetzt: `checkInterval` steht auf 180 Sekunden, falls es nach der Handprobe nicht gelöscht wurde. Zurücksetzen mit `defaults delete io.github.muunleit-projects.thetap checkInterval` (App vorher beenden).
- Offene Frage zum Plan: „Jetzt prüfen“ übergeht laut Plan die Bedingung „kein Upgrade läuft“. Klickt der Nutzer während „Upgrade läuft“, läuft `brew update` parallel zu `brew upgrade` im Terminal; ob brew das sperrt, ist nicht geprüft. Entscheidung des Nutzers steht aus (so lassen oder den Knopf während eines Upgrades deaktivieren). Antwort: während ein Upgrade läuft, ist der Knopf deaktiviert; der Nutzer kann ihn nicht klicken.
- Offene Frage für Schritt 5: Zählt der Recheck nach einem Upgrade (`recheckAfterUpgrade`) als manuelle oder als automatische Prüfung für `showsFailure`? Der Plan nennt nur „Jetzt prüfen“ als manuell. Entscheidung des Nutzers steht aus. AAntwort: als automatische Prüfung, da der Nutzer den Recheck nicht selbst auslöst.
- Signierung im Alltag (Phase 5), Updates mit Ad-hoc-Signierung (Phase 7b) und Standardwerte (nach einer Woche Alltag) sind weiter offen, siehe PLAN.md unter „Offene Punkte“.

## Nächster Schritt

Phase 5, Schritt 5 – Stille Wiederholung, nach „Prüfplan → Fehlschläge“ in PLAN.md:

- `AppState` unterscheidet manuelle und automatische Prüfungen. „Jetzt prüfen“ ist manuell, `checkIfDue()` automatisch (Recheck: siehe offene Frage).
- Ein manueller Fehlschlag setzt `consecutiveFailures` vorher zurück und zeigt den Fehler sofort. Ein automatischer nutzt `Policies.showsFailure(consecutiveFailures:manual:)`; bei einem stillen Fehlschlag bleiben die letzte Paketliste und die vorige Phase stehen (dafür gibt es `restorePhase()`), der nächste Wecker versucht es erneut. Das Fehlschlag-Zählen und die Offline-Regel (`failCheck`) bleiben erhalten.
- Eine Änderung an `AppState.swift` und sehr wahrscheinlich an der Stelle, an der `PanelView` „Jetzt prüfen“ aufruft; `PanelView.swift` ist dafür nötig.
- Handprobe: Fehlschläge lassen sich z. B. erzwingen, indem man brew kurzzeitig unerreichbar macht; das Vorgehen klärt die KI mit dem Nutzer, ohne zu raten. Geprüft wird: zwei automatische Fehlschläge bleiben stumm, der dritte wird sichtbar, „Jetzt prüfen“ zeigt einen Fehler sofort.
- Abnahmekriterium dazu: „Die Regeln für stille Wiederholung sind in `PoliciesTests` abgedeckt und grün“ (die Tests dafür gibt es seit Schritt 2).

Danach Schritt 6 (Mitteilungen senden, `App/Notifier.swift`) und Schritt 7 (Aktion und Delegate).

Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`, `App/AppState.swift`, `App/Views/PanelView.swift`.
