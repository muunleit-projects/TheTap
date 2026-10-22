# TheTap – Bauplan für die KI

20.10.2026 · @M.

## Zweck und Kontext

TheTap ist eine Menüleisten-App für macOS, die regelmäßig prüft, welche Homebrew-Pakete veraltet sind, darüber per Mitteilung informiert und auf Klick alle Upgrades im Terminal startet. Sie ist in erster Linie für den Eigengebrauch gedacht; andere können die fertig gebaute App von GitHub herunterladen (Phase 7).

Vorbild ist [muunleit-projects/show_updates](https://github.com/muunleit-projects/show_updates): eine Go-App mit Fyne-Fenster, das beim Login `brew update` und `brew outdated` ausführt. TheTap baut die Idee in Swift neu und ersetzt das Fenster durch ein Icon in der Menüleiste, das selbstständig prüft.

Dieses Dokument ist die Arbeitsanweisung für die KI, die die App baut. Lies es zu Beginn jeder Sitzung ganz. Die Entscheidungen im Abschnitt „Feste Entscheidungen“ gelten; willst du davon abweichen, frag zuerst den Nutzer. Den aktuellen Stand der Arbeit hält `docs/STATUS.md` fest. Widerspricht eine hochgeladene Datei dem Plan, gilt die Datei; sprich den Widerspruch an und passe den Plan an.

## Arbeitsregeln für die KI

Der Nutzer hat keine Erfahrung mit Swift und Xcode, aber etwas mit Visual Studio Code, und verlässt sich auf dich. Arbeite deshalb in kleinen, überprüfbaren Schritten und erkläre alles, was er selbst tun muss.

- **Arbeitsweise: Chat.** Du arbeitest im Chat (Claude, Free-Plan) und hast keinen Zugriff auf den Mac. Der Nutzer führt jeden Befehl selbst aus und kopiert dir das Ergebnis in den Chat. Verlass dich nicht darauf, das Repo lesen zu können; maßgeblich sind die Dateien, die der Nutzer hochlädt oder hineinkopiert.
- **Sitzungsstart.** Jeder neue Chat beginnt im selben Projekt und mit dem Vorwissen daraus. Der Nutzer lädt zu Beginn `PLAN.md` und `STATUS.md` hoch, dazu die Dateien, die in `STATUS.md` unter „Nächster Schritt“ stehen. Arbeite nur mit Dateiinhalten, die dir in diesem Chat vorliegen; frag nach einer Datei, statt ihren Inhalt zu raten.
- **Sitzungsende.** Am Ende jedes Chats, oder wenn der Nutzer es verlangt, lieferst du eine aktualisierte `docs/STATUS.md`: aktuelle Phase und aktueller Schritt, letzter Commit, erledigte Schritte, Erkenntnisse, offene Probleme, nächster Schritt und die Liste der Dateien für den nächsten Chat. Erkenntnisse, die dauerhaft gelten (Toolchain, Verhalten von brew, neue Entscheidungen), trägst du zusätzlich in `PLAN.md` ein.
- **Ein Schritt pro Antwort.** Jede Antwort enthält einen überschaubaren Schritt: welche Dateien, ihr vollständiger Inhalt, die Befehle zum Prüfen und die erwartete Ausgabe. Danach wartest du auf die Rückmeldung.
- **Immer ganze Dateien.** Gib jede neue oder geänderte Datei vollständig aus, mit ihrem Pfad als Überschrift, nie als Ausschnitt oder Diff. Der Nutzer ersetzt den Dateiinhalt komplett. Halte Dateien klein, lieber mehrere kurze als eine lange. Ausnahmen sind `PLAN.md` und `RELEASE.md`: Dort gibst du nur die geänderten Abschnitte aus, jeden vollständig von seiner Überschrift (in `RELEASE.md`: vom fett gesetzten Schritt-Titel) bis zur nächsten, und sagst, welchen Abschnitt er ersetzt.
- **Erst grün, dann weiter.** Nach jeder Änderung lässt du den Nutzer `swift build` und `swift test` im Package ausführen, ab Phase 3 zusätzlich `scripts/build.sh`. Bei Fehlern zuerst reparieren.
- **Ausgaben kurz halten.** Bei langen Ausgaben bittest du nur um die Fehlermeldungen oder die letzten Zeilen und nennst den passenden Befehl, z. B. `swift test 2>&1 | tail -40`.
- **Sparsam mit dem Kontingent.** Der Free-Plan hat ein Nutzungslimit, das sich alle fünf Stunden erneuert. Keine langen Erklärungen ohne Anlass und keinen Code doppelt ausgeben.
- **Editor ist VS Code.** Der Nutzer arbeitet in Visual Studio Code mit der offiziellen Swift-Erweiterung, nicht in der Xcode-Oberfläche. Alles muss sich per Terminal-Befehl oder VS-Code-Task bauen, testen und starten lassen. Setzt ein Schritt doch Xcode voraus, kennzeichne ihn ausdrücklich als Ausnahme.
- **Klickanleitungen für den Nutzer.** Alles, was er in VS Code, im Finder oder in den Systemeinstellungen tun muss, beschreibst du als nummerierte Schrittfolge mit den genauen Menü- und Knopfnamen.
- **Befehle mit erwarteter Ausgabe.** Zu jedem Befehl sagst du, was der Nutzer sehen sollte und was er dir zurückmelden soll.
- **Fachbegriffe erklären.** Beim ersten Auftreten eines Swift-Begriffs ein Satz Erklärung.
- **Nichts erfinden.** Bei Unsicherheit über eine Apple-API, ein SF-Symbol oder ein brew-Flag sagst du das offen und lässt den Nutzer nachprüfen (z. B. mit `brew <befehl> --help`), statt zu raten.
- **Phasen-Abschluss.** Am Ende jeder Phase gehst du die Abnahmekriterien mit dem Nutzer durch; abgehakt wird erst, wenn er sie geprüft hat.
- **Sprache.** Code, Bezeichner, Kommentare und Commit-Messages auf Englisch; alle Texte, die der Nutzer in der App oder CLI sieht, auf Deutsch.
- **Keine Fremdbibliotheken.** Nur Apple-Frameworks und die Swift-Standardbibliothek. XcodeGen ist ein Werkzeug, keine Abhängigkeit der App.
- **Git.** Nach jedem abgeschlossenen Schritt nennst du die Befehle zum Committen und Pushen samt Commit-Nachricht. Das generierte `TheTap.xcodeproj` und der Ordner `build/` werden nicht eingecheckt. `App/Info.plist` erzeugt XcodeGen ebenfalls; sie wird aber eingecheckt und nur über `project.yml` geändert. Die GitHub-Actions-Prüfung ist eine zusätzliche Kontrolle; ihr Ergebnis meldet der Nutzer, wenn sie rot wird.

## Feste Entscheidungen

Diese Punkte sind mit dem Nutzer abgestimmt und werden nicht ohne Rücksprache geändert.

- **Name und Kennungen:** App `TheTap.app`, Bundle-ID `io.github.muunleit-projects.thetap` (nie mehr ändern), URL-Schema `thetap`, Logordner `~/Library/Logs/TheTap/`.
- **Plattform:** Nur macOS, Mindestversion macOS 26 (Tahoe), in `project.yml` und `Package.swift`. _Grund:_ Gebaut für den Mac des Nutzers; die neuesten SwiftUI-APIs sind nutzbar. Wer die App herunterlädt, braucht ebenfalls macOS 26.
- **Entwicklungsumgebung:** VS Code mit der offiziellen Swift-Erweiterung (swiftlang); Xcode ist nur installiert (Compiler, SDK, `xcodebuild`). _Grund:_ Der Nutzer kennt VS Code; alles läuft per Befehl.
- **Toolchain:** Lokal Xcode 27.1 mit Swift 6.4, in der CI Xcode 26.6 mit Swift 6.3.3. Deshalb `swift-tools-version: 6.0` in `Package.swift` und nur APIs, die es im SDK von Xcode 26 gibt. Maßstab ist die CI: Was dort nicht baut, gilt als Fehler. _Grund:_ Auch die Release-Builds entstehen auf dem GitHub-Runner.
- **Sprache und UI:** Swift 6 im Sprachmodus 6, SwiftUI; AppKit nur, wo SwiftUI nicht reicht. _Grund:_ Menüleiste, Mitteilungen und Login-Start sind eingebaute macOS-Funktionen.
- **Form:** Menüleisten-App ohne Dock-Icon: `MenuBarExtra` mit Stil `.window`, `LSUIElement = YES`. _Grund:_ Ein Panel mit scrollbarer Paketliste und Knöpfen statt eines schlichten Menüs.
- **Prüfung:** `brew update`, danach `brew outdated --json=v2 --greedy`. _Grund:_ Wie das Vorbild; `--greedy` erfasst auch Casks mit eigenem Updater.
- **Upgrade:** Alles auf einmal im Terminal: `brew upgrade --greedy --no-ask` über ein temporäres `.command`-Skript; es öffnet sich auf dem Mac des Nutzers in der Terminal-App. _Grund:_ Manche Casks fragen nach dem sudo-Passwort und brauchen ein echtes Terminal; kein AppleScript-Berechtigungsdialog.
- **Mitteilungen:** `UserNotifications`, nur wenn neue veraltete Pakete dazukommen. _Grund:_ Nicht bei jeder Prüfung erneut stören.
- **Autostart:** `SMAppService.mainApp`, Schalter in den Einstellungen. _Grund:_ Offizieller Weg seit macOS 13.
- **Sandbox:** App Sandbox ausgeschaltet. _Grund:_ Eine Sandbox-App darf `/opt/homebrew/bin/brew` nicht starten.
- **CLI:** Bleibt als Entwicklerwerkzeug zum Testen der Kernlogik. _Grund:_ Im Alltag nutzt der Nutzer nur die Menüleisten-App.
- **Signierung:** Ad hoc (`CODE_SIGN_IDENTITY: "-"` in `project.yml`), lokal und in GitHub Actions. **Kein Apple Developer Program** (entschieden am 20.10.2026), also keine Developer-ID-Signatur und keine Notarisierung. _Grund:_ Kostenlos; Mitteilungs-Erlaubnis und Login-Start hängen an der Bundle-ID. Folge: Wer die App herunterlädt, muss sie beim ersten Start in den Systemeinstellungen freigeben.
- **Verteilung:** GitHub Releases: Ein Versions-Tag `vX.Y.Z` startet `.github/workflows/release.yml`; der Workflow baut eine Release-App für Apple Silicon und Intel und hängt sie als ZIP an den Release. _Grund:_ Kostenlos, ohne eigenen Server; gebaut wird auf einem sauberen GitHub-Runner, nicht auf dem Mac des Nutzers.
- **Versionsnummer:** Der Tag gibt die Version vor (`v0.2.0` → `0.2.0`); `MARKETING_VERSION` in `project.yml` wird vor dem Taggen auf dieselbe Nummer gesetzt. _Grund:_ `Info.plist` liest Version und Build-Nummer aus den Build-Einstellungen.
- **Repo:** [muunleit-projects/TheTap](https://github.com/muunleit-projects/TheTap), Branch `main`, auf den Mac geklont nach `~/Programmieren/swift/TheTap`.
- **CI:** GitHub Actions auf dem Runner `macos-26`: `swift test` und App-Build bei jedem Push auf `main` und bei Pull Requests, ohne `if:`-Bedingungen. _Grund:_ Zweite, unabhängige Prüfung neben den Testläufen des Nutzers.

## Architektur und Projektstruktur

Alle Logik, die ohne Oberfläche auskommt, liegt in der Bibliothek BrewCheck; die App ist nur eine dünne Hülle darum. So lässt sich der Kern mit `swift test` und der CLI prüfen, ohne Xcode zu öffnen.

```text
TheTap.app (SwiftUI) ─┐
                      ├──► BrewCheck (Bibliothek) ──Process──► brew update / outdated
brewcheck-cli ────────┘

TheTap.app ──.command-Skript──► Terminal: brew upgrade ──thetap://recheck──► TheTap.app
```

- **BrewCheck** (Swift Package, Bibliothek): brew finden, Befehle mit Timeout ausführen, JSON parsen, den Text des Upgrade-Skripts erzeugen, deutsche Fehlertexte, dazu reine Entscheidungsregeln (`Policies`).
- **brewcheck-cli** (Swift Package, ausführbar): ruft BrewCheck auf und gibt die Liste im Terminal aus. Nur zum Testen.
- **TheTap** (App-Target): Menüleiste, Zustand, Netzwerkstatus, Zeitplan, Mitteilungen, Upgrade-Start, Einstellungen.

```text
TheTap/                          # Repo-Wurzel
├── project.yml                  # XcodeGen-Beschreibung des App-Projekts
├── README.md
├── LICENSE                      # MIT
├── Packages/BrewCheck/
│   ├── Package.swift
│   ├── Sources/
│   │   ├── BrewCheck/           # Bibliothek
│   │   └── BrewCheckCLI/        # ausführbares Produkt "brewcheck-cli"
│   └── Tests/BrewCheckTests/
│       └── Fixtures/            # JSON-Beispiele, real.json aus echtem brew
├── App/
│   ├── TheTapApp.swift          # @main, MenuBarExtra (Settings ab Phase 6)
│   ├── AppDelegate.swift        # hält AppState, URL-Schema, ab Phase 5 Mitteilungs-Delegate
│   ├── AppState.swift           # @Observable, @MainActor
│   ├── NetworkMonitor.swift     # NWPathMonitor
│   ├── UpgradeLauncher.swift
│   ├── Scheduler.swift          # ab Phase 5
│   ├── Notifier.swift           # ab Phase 5
│   ├── Views/                   # MenuBarLabel, PanelView, PackageListView
│   ├── Info.plist               # von XcodeGen erzeugt, eingecheckt
│   └── Assets.xcassets          # ab Phase 6 (App-Icon)
├── scripts/
│   ├── build.sh                 # xcodegen generate + xcodebuild (Debug)
│   ├── run.sh                   # bauen, laufende App beenden, neu starten
│   └── install.sh               # ab Phase 6: Release-Build nach /Applications
├── .vscode/
│   ├── tasks.json               # Tasks: Test, CLI, App bauen, App starten
│   └── extensions.json          # empfiehlt die Swift-Erweiterung
├── .github/workflows/
│   ├── ci.yml                   # swift test + App-Build auf macOS
│   └── release.yml              # ab Phase 7a: bei Tag vX.Y.Z Release-Build, ZIP, GitHub-Release
├── docs/PLAN.md                 # dieses Dokument
├── docs/RELEASE.md              # Anleitung für Phase 7a und jeden Release
├── docs/STATUS.md               # Fortschritt, von der KI am Ende jedes Chats aktualisiert
└── .gitignore                   # u. a. TheTap.xcodeproj/, build/, .build/
```

**Achtung Ordnernamen:** Der CLI-Ordner heißt `BrewCheckCLI`, nicht `brewcheck`. Das macOS-Dateisystem unterscheidet standardmäßig nicht zwischen Groß- und Kleinschreibung; `BrewCheck` und `brewcheck` wären derselbe Ordner.

**XcodeGen statt Xcode-Oberfläche:** Eine Mac-App braucht ein Xcode-Projekt, aber niemand muss es in Xcode öffnen. Mit [XcodeGen](https://github.com/yonaskolb/XcodeGen) beschreibt `project.yml` das Projekt als lesbaren Text; `xcodegen generate` erzeugt daraus `TheTap.xcodeproj`, und `xcodebuild` baut die App. Du änderst nur `project.yml`.

`project.yml` legt fest: Deployment Target macOS 26, Swift 6, die Bundle-ID, `LSUIElement = YES`, das URL-Schema `thetap`, kein App-Sandbox-Entitlement, Ad-hoc-Signierung (`CODE_SIGN_STYLE: Manual`, `CODE_SIGN_IDENTITY: "-"`) und die Abhängigkeit auf das lokale Package `Packages/BrewCheck`. Ab Phase 7a, Schritt 1 außerdem die Versionsnummer: `CFBundleShortVersionString: "$(MARKETING_VERSION)"` und `CFBundleVersion: "$(CURRENT_PROJECT_VERSION)"` unter `info → properties`. Ohne diese beiden Einträge schreibt XcodeGen fest `1.0` und `1` in `App/Info.plist`.

**Alltag in VS Code:** Der Nutzer öffnet den Repo-Ordner in VS Code und startet über „Terminal → Run Task …“ die Tasks aus `.vscode/tasks.json`: „Test“ (`swift test` im Package), „CLI“ (`swift run brewcheck-cli --no-update`), „App bauen“ (`scripts/build.sh`) und „App starten“ (`scripts/run.sh`). Eine `.vscode/settings.json` gibt es bewusst nicht: Die früher geplante Einstellung `swift.searchSubfoldersForPackages` existiert in der Erweiterung nicht (vorhanden ist `swift.ignoreSearchingForPackagesInSubfolders`). Ob die Erweiterung `Packages/BrewCheck` von selbst findet, steht in `STATUS.md` unter „Offene Probleme“.

## Kernbibliothek BrewCheck

BrewCheck führt `brew update` und `brew outdated --json=v2 --greedy` aus und liefert eine sortierte Liste veralteter Pakete oder einen klar benannten Fehler. Die Bibliothek importiert weder SwiftUI noch AppKit. Sie ist seit Phase 4 fertig bis auf die neuen Regeln für Phase 5; Code und Tests sind die genaue Quelle, dieser Abschnitt hält die Regeln fest.

**Datenmodell** (alle Typen `Sendable`):

```swift
public enum PackageKind: String, Sendable, Codable { case formula, cask }

public struct OutdatedPackage: Sendable, Hashable, Codable {
    public let name: String
    public let kind: PackageKind
    public let installedVersions: [String]
    public let currentVersion: String
    public let pinned: Bool
}

public struct PackageKey: Sendable, Hashable, Codable {
    public let name: String
    public let kind: PackageKind
    public let version: String
}

public enum BrewCheckError: Error, Sendable {
    case brewNotFound(searched: [String])
    case commandFailed(command: [String], exitCode: Int32, output: String)
    case timedOut(command: [String], after: Duration)
    case invalidJSON(String)
    case cancelled
}
```

`PackageKey` bedeutet „dieses Paket in dieser Version“; `OutdatedPackage.key` liefert ihn mit `version = currentVersion`. Eine neue Version desselben Pakets ist ein neuer Schlüssel, Formula und Cask mit gleichem Namen sind verschieden.

**`BrewChecker`** ist ein `actor`, damit nie zwei Prüfungen gleichzeitig laufen:

```swift
public actor BrewChecker {
    public init(runner: any CommandRunner = ProcessRunner(),
                locator: BrewLocator = BrewLocator(),
                baseEnvironment: [String: String] = ProcessInfo.processInfo.environment,
                updateTimeout: Duration = .seconds(600),
                outdatedTimeout: Duration = .seconds(120))
    public func outdated(runUpdate: Bool = true, greedy: Bool = true) async throws -> [OutdatedPackage]
}
```

Ablauf: brew finden; wenn `runUpdate`, `brew update`; dann `brew outdated --json=v2`, plus `--greedy` wenn `greedy`. Jeder Exit-Code ungleich 0 ergibt `commandFailed` mit den letzten 200 Zeilen aus stdout und stderr, ohne zu parsen (geprüft: brew liefert 0, auch wenn Pakete veraltet sind). Geparst wird nur stdout; stderr enthält Warnungen.

Die übrigen Bausteine:

- **`BrewLocator`:** sucht brew erst in jedem Verzeichnis aus `PATH`, dann unter `/opt/homebrew/bin/brew` und `/usr/local/bin/brew`; ein Treffer muss ausführbar sein. `PATH` und Dateiprüfung sind injizierbar. Nichts gefunden → `brewNotFound` mit allen geprüften Pfaden.
- **`CommandRunner`:** Protokoll mit `run(_:arguments:environment:timeout:) async throws -> CommandResult` (`exitCode`, `stdout`, `stderr` als `Data`), damit Tests einen `FakeRunner` einsetzen können.
- **`ProcessRunner`** (Hilfstypen in `ProcessSupport.swift`): liest stdout und stderr parallel während des Laufs, sonst hängt der Prozess bei vollem Pipe-Puffer. Bei Zeitüberschreitung SIGTERM, nach 5 Sekunden SIGKILL, dann `timedOut`; bei Abbruch der Swift-`Task` dasselbe, dann `cancelled`. Wartet danach höchstens 5 Sekunden auf das Schließen der Pipes, weil Kindprozesse von brew sie offen halten können. Blockiert nie den Main Thread.
- **Umgebung für brew:** Ausgangspunkt ist `baseEnvironment`; Tests übergeben eine feste Umgebung, weil z. B. die GitHub-Runner `HOMEBREW_NO_AUTO_UPDATE=1` selbst setzen. `PATH` wird ersetzt durch das Verzeichnis von brew plus `/usr/bin:/bin:/usr/sbin:/sbin`, weil eine aus dem Finder oder beim Login gestartete App einen sehr kurzen `PATH` erbt. Immer `HOMEBREW_NO_ENV_HINTS=1`; nur bei `outdated` zusätzlich `HOMEBREW_NO_AUTO_UPDATE=1`, sonst aktualisiert `outdated` die API-Daten selbst.
- **`OutdatedParser`:** Format wie in `Fixtures/real.json`. Tolerant: fehlendes `formulae` oder `casks` = leere Liste, fehlendes `pinned` = `false`, unbekannte Felder ignorieren, `installed_versions` auch als einzelner String. Leere oder ungültige Ausgabe → `invalidJSON` mit den ersten 500 Zeichen. Sortierung: erst Formulae, dann Casks, jeweils nach Name (`localizedStandardCompare`).
- **`BrewCheckError.userMessage`** (`BrewCheckError+Message.swift`): eine deutsche Zeile pro Fall, gemeinsam für CLI und App (Texte unter „Fehlerbehandlung und Logging“).
- **`UpgradeScript.content(brewPath:greedy:)`:** Text des `.command`-Skripts (siehe „Upgrade“). Der brew-Pfad steht in einfachen Anführungszeichen, ein `'` darin wird zu `'\''`.

**Reine Regeln (`Policies`).** Alles, was die App entscheidet, aber ohne Oberfläche berechenbar ist, liegt hier als reine Funktion ohne Seiteneffekte:

- `isCheckDue(lastSuccess:interval:now:) -> Bool` – fällig, wenn es noch keine erfolgreiche Prüfung gab, das Intervall abgelaufen ist oder `lastSuccess` in der Zukunft liegt (Uhr verstellt).
- `newlyOutdated(current:alreadyNotified:) -> [OutdatedPackage]` – ein Paket ist neu, wenn sein `PackageKey` noch nicht gemeldet wurde. Angepinnte Pakete werden nie gemeldet.
- `pruneNotified(_:current:) -> Set<PackageKey>` – entfernt gemeldete Einträge für Pakete, die nicht mehr in dieser Version veraltet sind.
- `badgeCount(_:) -> Int` – zählt nur nicht angepinnte Pakete, weil `brew upgrade` angepinnte überspringt.
- Neu in Phase 5, Schritt 2:
  - `failuresBeforeError = 3` und `showsFailure(consecutiveFailures:manual:) -> Bool` – eine manuelle Prüfung zeigt einen Fehler sofort, eine automatische erst ab 3 Fehlschlägen in Folge.
  - `notificationText(newPackages:badgeCount:) -> NotificationText` (Struktur mit `title` und `body`). Titel: „1 Homebrew-Update verfügbar“ bzw. „3 Homebrew-Updates verfügbar“ (Zahl aus `badgeCount`). Text: die Namen der neuen Pakete, bis drei als „git, node und wget“, mehr als „git, node, wget und 1 weiteres“ bzw. „… und 2 weitere“.

## CLI

`brewcheck-cli` (fertig seit Phase 2) ruft `BrewChecker` auf und dient nur zum Testen. Aufruf im Ordner `Packages/BrewCheck`: `swift run brewcheck-cli [--no-update] [--no-greedy] [--json]`; die Optionen werden ohne Fremdbibliothek aus `CommandLine.arguments` gelesen. Ausgabe als Tabelle (Formulae, dann Casks, je Zeile `name  installiert → neu`, angepinnte mit „(angepinnt)“, ohne Pakete „Alles aktuell.“) oder mit `--json` als JSON. Fehler gehen auf stderr: `userMessage` plus Befehl, Exit-Code und die letzten 20 Zeilen. Exit-Code 0 bei erfolgreicher Prüfung, 1 bei Fehler, 2 bei falschen Optionen.

## Menüleisten-App

Die App zeigt ein Icon in der Menüleiste, das den Zustand auf einen Blick verrät, und öffnet beim Klick ein Panel mit der Paketliste. Sie prüft selbstständig, meldet neue Updates per Mitteilung und startet Upgrades im Terminal.

### Zustand (`AppState`)

`AppState` ist `@Observable` und `@MainActor` und die einzige Quelle der Wahrheit für die Oberfläche. Der `AppDelegate` besitzt ihn; `TheTapApp` liest ihn über `@NSApplicationDelegateAdaptor`. Er hält die Phase, die letzte Paketliste, den Zeitpunkt der letzten erfolgreichen Prüfung, den letzten Fehlertext, die Zahl der Fehlversuche in Folge, den Netzwerkstatus und ob gerade ein Upgrade läuft.

| Phase              | Icon in der Menüleiste                           | Kopfzeile im Panel                                |
| ------------------ | ------------------------------------------------ | ------------------------------------------------- |
| Noch nicht geprüft | `mug`                                            | „Noch nicht geprüft“                              |
| Prüft              | `arrow.triangle.2.circlepath`                    | „Prüfe auf Updates …“                             |
| Alles aktuell      | `mug`                                            | „Alles aktuell“                                   |
| Updates verfügbar  | `mug.fill` und die Zahl aus `badgeCount` daneben | „1 Update verfügbar“ / „3 Updates verfügbar“      |
| Offline            | `mug`                                            | „Offline – Prüfung folgt, sobald das Netz da ist“ |
| Fehler             | `exclamationmark.triangle`                       | Kurze Fehlerbeschreibung, ab Phase 6 „Log öffnen“ |

Die Namen sind SF Symbols und auf dem Mac des Nutzers bestätigt, ebenso `pin`. Prüfe jedes neue Symbol vor der Verwendung.

### Panel (`MenuBarExtra`, Stil `.window`)

1. Kopfzeile mit Phase und „Zuletzt geprüft: vor 12 Min.“ (`RelativeDateTimeFormatter`, deutsch, jede Minute neu berechnet).
2. Paketliste: erst Formulae, dann Casks; je Zeile Name und „installiert → neu“. Angepinnte Pakete grau mit Pin-Symbol. Ab 12 Zeilen scrollt die Liste, statt das Panel wachsen zu lassen.
3. Knöpfe: „Alles aktualisieren“ in eigener Zeile (nur aktiv bei mindestens einem nicht angepinnten Paket; während eines Upgrades deaktiviert mit Text „Upgrade läuft im Terminal …“), „Jetzt prüfen“ (während einer Prüfung deaktiviert), „Einstellungen …“ (ab Phase 6), „Beenden“.

### Prüfplan (`Scheduler`, Phase 5)

Alle automatischen Auslöser rufen denselben Einstiegspunkt `AppState.checkIfDue()`. `checkIfDue()` startet eine Prüfung mit `brew update` nur, wenn alles zutrifft:

1. Es läuft keine Prüfung.
2. Es läuft kein Upgrade. Sonst stößt `brew update` mit `brew upgrade` im Terminal zusammen; geprüft wird nach dem Recheck oder beim nächsten Auslöser.
3. Das Netz ist da. Sonst Phase „Offline“.
4. `isCheckDue` sagt ja. Nach einem Fehlschlag bleibt `lastSuccess` unverändert, die Prüfung ist also weiter fällig; daraus ergibt sich die Wiederholung von selbst.

„Jetzt prüfen“ und der Recheck nach einem Upgrade übergehen die Bedingungen 2 und 4.

Jede Entscheidung (geprüft oder übersprungen, mit Grund) wird mit `os.Logger`, Kategorie `scheduler`, geloggt, damit sich der Prüfplan in der App „Konsole“ nachvollziehen lässt.

**Prüfintervall:** gespeichert in `UserDefaults` unter `checkInterval` in Sekunden, Standard 21600 (6 Stunden). In Phase 6 schreibt das Einstellungsfenster denselben Schlüssel. Zum Testen lässt er sich vorher per Terminal setzen, z. B. auf 3 Minuten: `defaults write io.github.muunleit-projects.thetap checkInterval -float 180` (App vorher beenden). Zurück zum Standard mit `defaults delete io.github.muunleit-projects.thetap checkInterval`.

**Auslöser:**

- **Start:** 10 Sekunden nach dem Start, weil das Netz direkt nach dem Login oft noch fehlt.
- **Wecker:** `NSBackgroundActivityScheduler` mit `repeats = true`, Takt = Prüfintervall durch 3, höchstens 15 Minuten. Er prüft nicht selbst, sondern ruft nur `checkIfDue()`. Das System legt den Lauf in einen günstigen Moment und darf ihn etwas verschieben. Grund für den kurzen Takt: Liefe der Wecker im Prüfintervall und käme kurz davor eine manuelle Prüfung, folgte die nächste Prüfung erst nach fast dem doppelten Intervall.
- **Aufwachen:** `NSWorkspace.didWakeNotification` (sie kommt über `NSWorkspace.shared.notificationCenter`, nicht über das normale Notification Center), danach 60 Sekunden warten und `checkIfDue()`.
- **Netz wieder da** (`NetworkMonitor`): `checkIfDue()`; ist nichts fällig, zurück zur vorigen Phase.

**Fehlschläge:**

- Jeder Fehlschlag erhöht `consecutiveFailures`; eine erfolgreiche Prüfung setzt ihn auf 0.
- Ob ein Fehler sichtbar wird, entscheidet `Policies.showsFailure`. Bei einem stillen Fehlschlag bleiben die letzte Paketliste und die vorige Phase stehen; der nächste Wecker versucht es erneut. Typischer Grund: Der Nutzer benutzt gerade selbst brew.
- „Jetzt prüfen“ setzt den Zähler zurück und zeigt einen Fehler sofort.
- Ein Fehlschlag ohne Netz ergibt „Offline“, nicht „Fehler“.

**Recheck nach dem Upgrade** (`thetap://recheck`): beendet „Upgrade läuft“ und prüft ohne `brew update`. Läuft gerade eine Prüfung, wird der Recheck vorgemerkt und direkt nach ihrem Ende ausgeführt, statt verloren zu gehen.

### Mitteilungen (`Notifier`, Phase 5)

- Der `AppDelegate` ist `UNUserNotificationCenterDelegate` und setzt sich in `applicationWillFinishLaunching(_:)` als Delegate. Apple verlangt, dass das vor dem Ende des Starts geschieht; in der Doku zu `UNUserNotificationCenterDelegate` nachprüfen.
- Erlaubnis beim ersten Start mit `UNUserNotificationCenter.requestAuthorization(options: [.alert])` anfragen.
- Nach jeder erfolgreichen Prüfung `newlyOutdated` gegen die gespeicherte Menge gemeldeter Pakete aufrufen. Ist das Ergebnis nicht leer und sind Mitteilungen erlaubt, eine Mitteilung mit Titel und Text aus `Policies.notificationText` senden.
- Danach die Menge immer fortschreiben: neue Schlüssel ergänzen, mit `pruneNotified` aufräumen. Das gilt auch, wenn keine Mitteilung gesendet wurde (nicht erlaubt oder in den Einstellungen aus); sonst käme beim Einschalten eine Mitteilung über längst bekannte Pakete.
- Speicherort: `UserDefaults`, Schlüssel `notifiedPackages`, als JSON-codiertes Array von `PackageKey`. Zum Testen leeren mit `defaults delete io.github.muunleit-projects.thetap notifiedPackages` (App vorher beenden).
- Eine `UNNotificationCategory` mit der Aktion „Alles aktualisieren“ startet das Upgrade wie der Knopf im Panel; ist gerade kein Upgrade möglich, passiert nichts.
- `userNotificationCenter(_:willPresent:)` liefert `[.banner, .list]`, damit Mitteilungen auch erscheinen, während die App aktiv ist.
- Mitteilungen funktionieren nur in der gebündelten, signierten App, nicht über `swift run`.

### Upgrade (`UpgradeLauncher`)

Fertig seit Phase 4. `UpgradeLauncher` schreibt den Text aus `UpgradeScript.content` bei jedem Upgrade neu als `thetap-upgrade.command` in `FileManager.default.temporaryDirectory`, setzt die Rechte auf `0o755`, öffnet die Datei mit `NSWorkspace.shared.open(_:)` in der Terminal-App und setzt „Upgrade läuft“. Fehler kommen als `UpgradeLaunchError` mit deutschem `userMessage`. Das Skript (`<BREW>` ist der brew-Pfad in einfachen Anführungszeichen; `--greedy` nur, wenn die Einstellung aktiv ist):

```zsh
#!/bin/zsh
eval "$('<BREW>' shellenv)"
'<BREW>' upgrade --greedy --no-ask
echo
echo "Fertig. TheTap aktualisiert die Liste jetzt."
open -g "thetap://recheck"
read -k 1 "?Zum Schließen eine beliebige Taste drücken …"
```

- `thetap://recheck` löst eine Prüfung **ohne** `brew update` aus (die Daten sind frisch) und beendet den Zustand „Upgrade läuft“.
- Das Skript wartet am Ende auf einen Tastendruck, weil Terminal das Fenster sonst sofort schließt und die brew-Ausgabe nicht lesbar wäre. Der Recheck wird vorher ausgelöst.
- Kommt kein Recheck (Fenster vorher geschlossen), endet der Zustand nach 2 Stunden von selbst; die nächste reguläre Prüfung korrigiert die Liste.

### URL-Schema und App-Delegate

- `CFBundleURLTypes` mit dem Schema `thetap`, eingetragen über `project.yml`.
- Empfang über `@NSApplicationDelegateAdaptor` und `application(_:open:)` im `AppDelegate`; das klappt auch in einer reinen `MenuBarExtra`-App ohne Fenster. Unbekannte URLs ignorieren und loggen (Kategorie `upgrade`).
- Der `AppDelegate` hält `AppState` und `NetworkMonitor`, ab Phase 5 auch den Scheduler, und ist zugleich `UNUserNotificationCenterDelegate`.
- Zwei Kopien mit derselben Bundle-ID (Debug-Build in `build/`, installierte App in `/Applications` oder ein Download) dürfen nie gleichzeitig laufen, sonst landet `thetap://recheck` womöglich in der falschen. `scripts/run.sh` beendet jede laufende TheTap.

### Einstellungen (Phase 6)

SwiftUI-`Settings`-Szene, geöffnet über `SettingsLink` im Panel. In einer App ohne Dock-Icon erscheint das Fenster leicht hinter anderen Fenstern; stell sicher, dass es nach vorne kommt (`NSApp.activate()`). Werte mit `@AppStorage` speichern.

- Prüfintervall: 1, 3, 6, 12 oder 24 Stunden, Standard 6, gespeichert unter `checkInterval` in Sekunden. Ändert sich der Wert, legt der Scheduler den Wecker neu an.
- Beim Anmelden starten: `SMAppService.mainApp.register()` bzw. `unregister()`. Den Status bei jedem Öffnen aus `SMAppService.mainApp.status` lesen, weil der Nutzer ihn auch in den Systemeinstellungen ändern kann. Nur mit der Kopie in `/Applications` einschalten und testen: Bei zwei Kopien mit derselben Bundle-ID ist nicht verlässlich, welche beim Anmelden startet.
- Mitteilungen senden (an/aus). Sind sie in den Systemeinstellungen verboten, einen Hinweis mit Knopf dorthin zeigen.
- Casks mit eigenem Updater einbeziehen (`--greedy`), Standard an. Gilt für Prüfung und Upgrade; bis dahin ist beides fest an.
- Knopf „Log im Finder zeigen“.

## Fehlerbehandlung und Logging

Die App stürzt nie wegen brew ab und blockiert nie die Oberfläche; jeder Fehler wird geloggt und dem Nutzer kurz und verständlich angezeigt.

- **Systemlog:** `os.Logger` mit der Bundle-ID als Subsystem und den Kategorien `check`, `scheduler`, `upgrade`, `notifications`. Der Nutzer sieht es in der App „Konsole“ (nach dem Subsystem filtern). Bis zur Logdatei in Phase 6 stehen Fehlerdetails nur dort.
- **Logdatei (Phase 6):** Fehlerdetails (Befehl, Exit-Code, die letzten 200 Zeilen Ausgabe) zusätzlich nach `~/Library/Logs/TheTap/thetap.log`. Ab 1 MB wird die Datei in `thetap.log.1` umbenannt und neu begonnen. Nicht `/tmp` verwenden, das leert macOS.
- **Meldungen in der Oberfläche:** eine Zeile auf Deutsch, die sagt, was zu tun ist (`BrewCheckError.userMessage`):
  - `brewNotFound` → „Homebrew nicht gefunden. Erwartet unter /opt/homebrew oder /usr/local.“
  - `timedOut` → „brew hat nicht rechtzeitig geantwortet. Neuer Versuch folgt.“
  - `commandFailed` → „brew meldet einen Fehler. Details im Log.“
  - `invalidJSON` → „Unerwartete Antwort von brew. Details im Log.“
  - `cancelled` → „Die Prüfung wurde abgebrochen.“
- **Keine sensiblen Daten** ins Log außer der brew-Ausgabe selbst; keine Umgebungsvariablen vollständig loggen.

## Teststrategie

Die Bibliothek BrewCheck wird vollständig automatisch getestet, ohne dass dabei echtes brew läuft; die App wird anhand der Abnahmekriterien von Hand geprüft (keine UI-Tests). Testframework ist Swift Testing (`import Testing`), ausgeführt mit `swift test` im Package.

Jede Komponente hat eine eigene Testdatei: `OutdatedParserTests` (Fixtures `real.json` als echte Ausgabe des Nutzers, `empty.json`, `formulae-only.json`, `casks-only.json`, `pinned.json`, `extra-fields.json`, `broken.json`, `blank.json` als leere Datei), `BrewLocatorTests` (injizierter `PATH`), `ProcessRunnerTests` (echte, harmlose Systembefehle: Exit-Codes, getrennte Ausgaben, mehrere MB, Timeout, Abbruch), `BrewCheckerTests` (mit `FakeRunner`: Argumente, Umgebung, Fehlerfälle), `PoliciesTests` (Tabellen inklusive angepinnter Pakete und neuer Versionen), `UpgradeScriptTests`, `ErrorMessageTests` und `ModelsTests`. Neue Regeln bekommen ihre Tests in der passenden Datei.

Tests dürfen nie von der Umgebung der Maschine abhängen. Gegenprobe: `HOMEBREW_NO_AUTO_UPDATE=1 swift test` muss ebenfalls grün sein.

## Phasenplan

Acht Phasen (0 bis 7), jede endet mit einem lauffähigen Stand und Kriterien, die der Nutzer selbst abhakt. Eine Phase beginnt erst, wenn die vorige abgehakt ist. Ausnahme ist Phase 7a: Sie berührt den App-Code nicht und darf jederzeit vorgezogen werden, auch zwischen zwei Schritten einer anderen Phase. Phase 7b folgt nach Phase 6.

Größere Phasen sind in nummerierte Schritte geteilt. Jeder Schritt endet mit grünem `swift test`, grünem `scripts/build.sh` und einem Commit; `STATUS.md` nennt den aktuellen Schritt.

### Phase 0 – Werkzeuge und Repo ✓

Xcode, Swift-Erweiterung, `brew install xcodegen`, Repo auf GitHub und auf dem Mac, `.gitignore`, `docs/`, `.vscode/`, CI.

- [x] `swift --version` zeigt Swift 6 oder neuer
- [x] `xcodegen --version` funktioniert
- [x] Das Repo ist auf den Mac geklont, der Ordner öffnet sich in VS Code, die Swift-Erweiterung ist aktiv
- [x] Der erste Commit mit `docs/PLAN.md` liegt auf GitHub; die GitHub-Actions-Prüfung ist angelegt und wird ab Phase 1 grün

### Phase 1 – Kernbibliothek mit Tests ✓

Package `Packages/BrewCheck` mit Datenmodell, `BrewLocator`, `ProcessRunner`, `OutdatedParser`, `BrewChecker` und `Policies`.

- [x] `swift test` ist grün, alle Testgruppen aus der Teststrategie sind vorhanden
- [x] Der Parser liest die echte `real.json` des Nutzers korrekt

### Phase 2 – CLI ✓

`BrewCheckError.userMessage` und `brewcheck-cli`.

- [x] `swift run brewcheck-cli` zeigt dieselben Pakete wie `brew outdated --greedy`
- [x] `--no-update`, `--no-greedy` und `--json` funktionieren
- [x] Ohne Netz erscheint eine verständliche Fehlermeldung statt eines Absturzes

### Phase 3 – App-Gerüst ✓

`project.yml`, `scripts/build.sh`, `scripts/run.sh`, App mit `MenuBarExtra`, `AppState`, Panel mit Liste sowie „Jetzt prüfen“ und „Beenden“.

- [x] `scripts/build.sh` läuft ohne Fehler, lokal und in GitHub Actions
- [x] Die VS-Code-Tasks „App bauen“ und „App starten“ funktionieren
- [x] Die App startet ohne Dock-Icon und zeigt ihr Icon in der Menüleiste
- [x] „Jetzt prüfen“ zeigt die echten Pakete; das Panel bleibt während der Prüfung bedienbar
- [x] Das Icon zeigt die richtige Zahl

### Phase 4 – Upgrade und Recheck ✓

`UpgradeScript`, `UpgradeLauncher`, URL-Schema `thetap://recheck`, Zustand „Upgrade läuft“.

- [x] „Alles aktualisieren“ öffnet das Terminal und startet das Upgrade
- [x] Nach dem Ende des Upgrades aktualisiert sich die Liste von selbst
- [x] Angepinnte Pakete bleiben sichtbar, zählen aber nicht mit

### Phase 5 – Automatik und Mitteilungen

Die App prüft selbstständig, wiederholt still nach Fehlschlägen und meldet neue Updates per Mitteilung. Spezifikation unter „Prüfplan“ und „Mitteilungen“.

1. **Netzwerk und Offline-Phase** – committet in `8c568ca`: `NetworkMonitor` (`NWPathMonitor`), `AppState.networkChanged(isOnline:)`; ein Fehlschlag ohne Netz ergibt „Offline“.
2. **Neue Regeln in `Policies`** – committet in `af55f21`: `failuresBeforeError`, `showsFailure` und `notificationText` samt Tests in `PoliciesTests`. `consecutiveFailures` zählt den aktuellen Fehlschlag mit: ein automatischer Fehler wird ab dem 3. Fehlschlag in Folge sichtbar. Nur das Package, keine App-Änderung.
3. **Einstiegspunkt und Recheck** – committet in `56688cb`: `AppState.checkIfDue()` mit den vier Bedingungen und Logging, Prüfintervall aus `checkInterval`, vorgemerkter Recheck; `networkChanged` nutzt `checkIfDue()`.
4. **Scheduler** – committet (Push-Stand `8536dbf`): `App/Scheduler.swift` mit Start nach 10 Sekunden, Wecker per `NSBackgroundActivityScheduler` und Aufwachen; der `AppDelegate` startet ihn.
5. **Stille Wiederholung** – `AppState` nutzt `showsFailure`; stille Fehlschläge lassen Liste und Phase stehen.
6. **Mitteilungen senden** – `App/Notifier.swift`: Erlaubnis, Text aus `notificationText`, Menge `notifiedPackages` fortschreiben.
7. **Aktion und Delegate** – Kategorie mit „Alles aktualisieren“, `AppDelegate` als `UNUserNotificationCenterDelegate`, `willPresent`.

Abnahme (für Tests mit `checkInterval` von 3 Minuten, danach zurücksetzen):

- [x] WLAN aus → Phase „Offline“; WLAN wieder an → die fällige Prüfung folgt
- [x] `open "thetap://recheck"` während einer laufenden Prüfung: Direkt danach folgt eine zweite Prüfung (Log in „Konsole“)
- [x] Während „Upgrade läuft“ startet keine automatische Prüfung (Log: übersprungen)
- [x] Ohne Zutun folgt nach Ablauf des Prüfintervalls eine neue Prüfung; das System darf den Wecker um einige Minuten verschieben
- [x] Nach dem Aufwachen aus dem Ruhezustand folgt eine fällige Prüfung nach etwa einer Minute
- [ ] Die Regeln für stille Wiederholung sind in `PoliciesTests` abgedeckt und grün
- [ ] Beim ersten Start mit Mitteilungen fragt macOS nach der Erlaubnis
- [ ] Nach `defaults delete … notifiedPackages` ergibt die nächste Prüfung genau eine Mitteilung, eine weitere Prüfung ohne Änderung keine
- [ ] Die Aktion „Alles aktualisieren“ in der Mitteilung startet das Upgrade
- [ ] Erlaubnis und Mitteilungen funktionieren auch nach einem Neubau mit `scripts/run.sh` (klärt den offenen Punkt „Signierung im Alltag“)

### Phase 6 – Einstellungen, Login-Start, Feinschliff

1. **Logdatei** – nach „Fehlerbehandlung und Logging“; „Log öffnen“ in der Phase „Fehler“.
2. **Einstellungsfenster** – `Settings`-Szene, `SettingsLink` im Panel, Fenster nach vorne; Prüfintervall, Mitteilungen an/aus, `--greedy`, „Log im Finder zeigen“.
3. **Installation** – `scripts/install.sh`: Release-Build, laufende TheTap beenden, nach `/Applications` kopieren und starten. Ab jetzt läuft im Alltag nur diese Kopie. `scripts/run.sh` beendet sie beim Entwickeln; danach startet der Nutzer sie wieder mit `open /Applications/TheTap.app`.
4. **Beim Anmelden starten** – `SMAppService` in den Einstellungen; nur mit der Kopie in `/Applications` einschalten und testen.
5. **App-Icon** – Woher das Bild (1024 × 1024 Pixel) kommt, klärt die KI vorher mit dem Nutzer. Ein Skript erzeugt daraus mit `sips` die Größen für `App/Assets.xcassets/AppIcon.appiconset`; `project.yml` setzt `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`. Vorher prüfen, ob macOS 26 ein solches Icon-Set noch richtig darstellt. Apples neues Werkzeug Icon Composer wäre eine eigene App und damit eine Ausnahme von der VS-Code-Regel.
6. **Eine Woche Alltag** – danach die Standardwerte prüfen (offener Punkt).

- [ ] Die Einstellungen öffnen sich im Vordergrund; alle Werte bleiben nach einem Neustart der App erhalten
- [ ] Ein geändertes Prüfintervall wirkt ohne Neustart der App
- [ ] „Beim Anmelden starten“ funktioniert nach Ab- und Anmelden
- [ ] Bei einem Fehler entsteht die Logdatei unter `~/Library/Logs/TheTap/`; „Log öffnen“ zeigt sie
- [ ] Die App hat ein eigenes Icon im Finder und in Mitteilungen
- [ ] Die App liegt in `/Applications` und läuft eine Woche ohne Auffälligkeiten

### Phase 7a – Build und Release über GitHub

GitHub Actions baut die App bei jedem Versions-Tag `v…` als Release-Build für Apple Silicon und Intel und hängt sie als ZIP an einen GitHub-Release. Die App ist ad hoc signiert und nicht notarisiert; macOS blockiert sie deshalb beim ersten Start, bis der Nutzer sie in den Systemeinstellungen freigibt.

Die fertige Anleitung samt `release.yml` steht in `docs/RELEASE.md`. Schritte: Versionsnummer aus den Build-Einstellungen, Release-Workflow, Testrelease, Download auf dem Mac testen, README, Testrelease löschen; dazu der Ablauf für jeden späteren Release. Solange Phase 6 nicht abgehakt ist, gibt es nur Vorabversionen mit Bindestrich (`v0.1.0-test.1`); danach `v1.0.0`.

Abnahme:

- [ ] Ein Tag `v…` startet den Lauf „Release“, und er wird grün
- [ ] „Check build“ zeigt die Version aus dem Tag (ohne den Zusatz nach dem Bindestrich), beide Architekturen und `Signature=adhoc`
- [ ] Am Release hängt `TheTap-<Version>.zip`; Tags mit Bindestrich erscheinen als „Pre-release“
- [ ] Die heruntergeladene App startet nach der Freigabe in den Systemeinstellungen und funktioniert wie der lokale Build
- [ ] Die README beschreibt Download, Installation und Freigabe mit den echten Texten aus macOS

### Phase 7b – Erster Release nach Phase 6

Klärt, was beim Ersetzen einer heruntergeladenen Version durch eine neuere passiert. Jeder Ad-hoc-Build hat eine andere Signatur; ob macOS Freigabe, Mitteilungs-Erlaubnis und Login-Start behält, lässt sich nur so prüfen.

1. Nach Abschluss von Phase 6 `MARKETING_VERSION` auf `1.0.0` setzen und `v1.0.0-beta.1` veröffentlichen (Ablauf in `docs/RELEASE.md`).
2. Die lokale Kopie in `/Applications` durch den Download ersetzen, freigeben, Mitteilungen erlauben und „Beim Anmelden starten“ einschalten. Einige Tage so benutzen.
3. `v1.0.0` veröffentlichen, herunterladen und die Version in „Programme“ ersetzen.
4. Prüfen und in der README unter „Update“ festhalten: Ist die Freigabe in „Datenschutz & Sicherheit“ erneut nötig? Bleiben Mitteilungs-Erlaubnis und „Beim Anmelden starten“ erhalten?

- [ ] Die neuere Version ersetzt die ältere; die README sagt, ob Freigabe, Mitteilungs-Erlaubnis und „Beim Anmelden starten“ erhalten bleiben oder neu eingeschaltet werden müssen

## Offene Punkte

Diese Punkte sind noch nicht geklärt. Kläre sie in der genannten Phase und trage die Antwort unter „Feste Entscheidungen“ ein.

- [ ] **Signierung im Alltag:** In Phase 5 prüfen, ob Mitteilungen mit Ad-hoc-Signierung zuverlässig funktionieren, auch nach einem Neubau; in Phase 6 dasselbe für den Login-Start. Falls nicht: kostenloses „Personal Team“ mit der Apple-ID des Nutzers einrichten (einmalig in Xcode, als Ausnahme von der VS-Code-Regel), aber nur für den lokalen Build. Die Releases aus GitHub bleiben ad hoc; die README nennt dann die Einschränkung.
- [ ] **Updates mit Ad-hoc-Signierung:** Bleiben Freigabe, Mitteilungs-Erlaubnis und Login-Start nach dem Ersetzen durch eine neue Version erhalten? Prüfen in Phase 7b.
- [ ] **Standardwerte:** Prüfintervall 6 Stunden und `--greedy` an sind Vorschläge; der Nutzer kann sie nach einer Woche Alltag (Phase 6) anpassen.

## Quellen

- [muunleit-projects/show_updates](https://github.com/muunleit-projects/show_updates) – Vorbild, insbesondere [checkupdates.go](https://raw.githubusercontent.com/muunleit-projects/show_updates/main/pkg/checkupdates/checkupdates.go)
- [Homebrew-Manpage](https://docs.brew.sh/Manpage) – Optionen von `outdated` und `upgrade` (`--json=v2`, `--greedy`, `--no-ask`) und Umgebungsvariablen
- [XcodeGen](https://github.com/yonaskolb/XcodeGen), Standardwerte der Info.plist in [InfoPlistGenerator.swift](https://github.com/yonaskolb/XcodeGen/blob/master/Sources/XcodeGenKit/InfoPlistGenerator.swift)
- [gh release create](https://cli.github.com/manual/gh_release_create) – Optionen `--verify-tag`, `--prerelease`, `--generate-notes`
- [Apple: Safely open apps on your Mac](https://support.apple.com/en-us/102445) – Freigabe nicht notarisierter Apps über „Datenschutz & Sicherheit“
