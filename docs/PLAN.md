# TheTap – Bauplan für die KI

Oct 12, 2026 · @M.

## Zweck und Kontext

TheTap ist eine Menüleisten-App für macOS, die regelmäßig prüft, welche Homebrew-Pakete veraltet sind, darüber per Mitteilung informiert und auf Klick alle Upgrades im Terminal startet. Sie ist nur für den Eigengebrauch auf einem Mac gedacht.

Vorbild ist [muunleit-projects/show_updates](https://github.com/muunleit-projects/show_updates): eine Go-App mit Fyne-Fenster, das beim Login `brew update` und `brew outdated` ausführt. TheTap baut die Idee in Swift neu und ersetzt das Fenster durch ein Icon in der Menüleiste, das selbstständig prüft.

Dieses Dokument ist die Arbeitsanweisung für die KI, die die App baut. Lies es zu Beginn jeder Sitzung ganz. Die Entscheidungen im Abschnitt „Feste Entscheidungen“ gelten; willst du davon abweichen, frag zuerst den Nutzer.

## Arbeitsregeln für die KI

Der Nutzer hat keine Erfahrung mit Swift und Xcode, aber etwas mit Visual Studio Code, und verlässt sich auf dich. Arbeite deshalb in kleinen, überprüfbaren Schritten und erkläre alles, was er selbst tun muss.

- **Arbeitsweise: Chat.** Du arbeitest im Chat (Claude, Free-Plan) und hast keinen Zugriff auf den Mac. Das Repo kannst du lesen. Der Nutzer führt jeden Befehl selbst aus und kopiert dir das Ergebnis in den Chat.
- **Sitzungsstart.** Jeder neue Chat beginnt im selben Projekt und mit dem Vorwissen daraus. Der Nutzer lädt zu Beginn `PLAN.md` und `STATUS.md` hoch, dazu die Dateien, um die es gerade geht. Arbeite nur mit Dateiinhalten, die dir in diesem Chat vorliegen; frag nach einer Datei, statt ihren Inhalt zu raten.
- **Sitzungsende.** Am Ende jedes Chats, oder wenn der Nutzer es verlangt, lieferst du eine aktualisierte `docs/STATUS.md`: aktuelle Phase, erledigte Schritte, offene Probleme, nächster Schritt.
- **Ein Schritt pro Antwort.** Jede Antwort enthält einen überschaubaren Schritt: welche Dateien, ihr vollständiger Inhalt, die Befehle zum Prüfen und die erwartete Ausgabe. Danach wartest du auf die Rückmeldung.
- **Immer ganze Dateien.** Gib jede neue oder geänderte Datei vollständig aus, mit ihrem Pfad als Überschrift, nie als Ausschnitt oder Diff. Der Nutzer ersetzt den Dateiinhalt komplett. Halte Dateien klein, lieber mehrere kurze als eine lange.
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
- **Git.** Das Repo liegt auf GitHub und ist auf den Mac geklont. Nach jedem abgeschlossenen Schritt nennst du die Befehle zum Committen und Pushen samt Commit-Nachricht. Das generierte `TheTap.xcodeproj` und der Ordner `build/` werden nicht eingecheckt. Die GitHub-Actions-Prüfung ist eine zusätzliche Kontrolle; ihr Ergebnis meldet der Nutzer, wenn sie rot wird.

## Feste Entscheidungen

Die App wird in Swift mit SwiftUI als Menüleisten-App für macOS 26 gebaut und in VS Code entwickelt. Die KI arbeitet im Chat (Claude Free-Plan); der Nutzer führt alles auf dem Mac aus. Diese Punkte sind mit dem Nutzer abgestimmt und werden nicht ohne Rücksprache geändert.

| Thema                  | Entscheidung                                                                                          | Grund                                                                                                             |
| ---------------------- | ----------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Plattform              | Nur macOS, Mindestversion macOS 26 (Tahoe)                                                            | Läuft nur auf dem Mac des Nutzers; die neuesten SwiftUI-APIs sind nutzbar                                         |
| Entwicklungsumgebung   | VS Code mit der offiziellen Swift-Erweiterung; Xcode 26 nur installiert (Compiler, SDK, `xcodebuild`) | Der Nutzer kennt VS Code; alles läuft per Befehl                                                                  |
| Sprache und UI         | Swift 6 im Sprachmodus 6, SwiftUI; AppKit nur, wo SwiftUI nicht reicht                                | Menüleiste, Mitteilungen und Login-Start sind eingebaute macOS-Funktionen                                         |
| Form                   | Menüleisten-App ohne Dock-Icon: `MenuBarExtra` mit Stil `.window`, `LSUIElement = YES`                | Ein Panel mit scrollbarer Paketliste und Knöpfen statt eines schlichten Menüs                                     |
| Prüfung                | `brew update`, danach `brew outdated --json=v2 --greedy`                                              | Wie das Vorbild; `--greedy` erfasst auch Casks mit eigenem Updater                                                |
| Upgrade                | Alles auf einmal im Terminal: `brew upgrade --greedy --no-ask` über ein temporäres `.command`-Skript  | Manche Casks fragen nach dem sudo-Passwort und brauchen ein echtes Terminal; kein AppleScript-Berechtigungsdialog |
| Mitteilungen           | `UserNotifications`, nur wenn neue veraltete Pakete dazukommen                                        | Nicht bei jeder Prüfung erneut stören                                                                             |
| Autostart              | `SMAppService.mainApp`, Schalter in den Einstellungen                                                 | Offizieller Weg seit macOS 13                                                                                     |
| Sandbox                | App Sandbox ausgeschaltet                                                                             | Eine Sandbox-App darf `/opt/homebrew/bin/brew` nicht starten                                                      |
| CLI                    | Bleibt als Entwicklerwerkzeug zum Testen der Kernlogik                                                | Im Alltag nutzt der Nutzer nur die Menüleisten-App                                                                |
| Signierung             | Lokal ad hoc (`CODE_SIGN_IDENTITY: "-"` in `project.yml`), feste Bundle-ID                            | Kein Developer-Account nötig; Mitteilungs-Erlaubnis und Login-Start hängen an der Bundle-ID                       |
| Repo                   | GitHub als Ablage, auf den Mac geklont. Name frei (Vorschlag `thetap`)                                | Swift stellt keine Anforderungen an den Repo-Namen                                                                |
| Prüfung bei jedem Push | GitHub Actions auf einem macOS-Runner: `swift test` und App-Build                                     | Zweite, unabhängige Prüfung neben den Testläufen des Nutzers                                                      |

## Architektur und Projektstruktur

Alle Logik, die ohne Oberfläche auskommt, liegt in der Bibliothek BrewCheck; die App ist nur eine dünne Hülle darum. So lässt sich der Kern mit `swift test` und der CLI prüfen, ohne Xcode zu öffnen.

&#91;embedded content: Architektur · App, Bibliothek BrewCheck, CLI und Homebrew\]

Die App enthält kaum eigene Logik: Prüfen, Parsen und Prozesse steuern liegen in BrewCheck und sind ohne Oberfläche testbar. Das Upgrade läuft im Terminal, das danach per URL eine neue Prüfung auslöst.

- **BrewCheck** (Swift Package, Bibliothek): brew finden, Befehle mit Timeout ausführen, JSON parsen, dazu reine Entscheidungsregeln (Ist eine Prüfung fällig? Welche Pakete sind neu?).
- **brewcheck-cli** (Swift Package, ausführbar): ruft BrewCheck auf und gibt die Liste im Terminal aus. Nur zum Testen.
- **TheTap** (App-Target): Menüleiste, Zustand, Zeitplan, Mitteilungen, Upgrade-Start, Einstellungen.

```text
thetap/                         # Repo-Wurzel (Name frei)
├── project.yml                 # XcodeGen-Beschreibung des App-Projekts
├── Packages/
│   └── BrewCheck/
│       ├── Package.swift
│       ├── Sources/
│       │   ├── BrewCheck/      # Bibliothek
│       │   └── BrewCheckCLI/   # ausführbares Produkt "brewcheck-cli"
│       └── Tests/
│           └── BrewCheckTests/
│               └── Fixtures/   # JSON-Beispiele aus echtem brew
├── App/
│   ├── TheTapApp.swift         # @main, MenuBarExtra + Settings
│   ├── AppDelegate.swift       # URL-Schema, Mitteilungs-Delegate
│   ├── AppState.swift          # @Observable, @MainActor
│   ├── Scheduler.swift
│   ├── Notifier.swift
│   ├── UpgradeLauncher.swift
│   ├── Views/
│   ├── Info.plist
│   └── Assets.xcassets
├── scripts/
│   ├── build.sh                # xcodegen generate + xcodebuild (Debug)
│   ├── run.sh                  # bauen, laufende App beenden, neu starten
│   └── install.sh              # Release-Build nach /Applications
├── .vscode/
│   ├── tasks.json              # Tasks: Test, CLI, App bauen, App starten
│   ├── settings.json           # Swift-Erweiterung findet Packages/BrewCheck
│   └── extensions.json         # empfiehlt die Swift-Erweiterung
├── .github/workflows/ci.yml    # swift test + App-Build auf macOS
├── docs/PLAN.md                # dieses Dokument als Markdown
├── docs/STATUS.md              # Fortschritt, von der KI am Ende jedes Chats aktualisiert
└── .gitignore                  # u. a. TheTap.xcodeproj/, build/, .build/
```

**Achtung Ordnernamen:** Der CLI-Ordner heißt `BrewCheckCLI`, nicht `brewcheck`. Das macOS-Dateisystem unterscheidet standardmäßig nicht zwischen Groß- und Kleinschreibung; `BrewCheck` und `brewcheck` wären derselbe Ordner.

**XcodeGen statt Xcode-Oberfläche:** Eine Mac-App braucht ein Xcode-Projekt, aber niemand muss es in Xcode öffnen. Mit [XcodeGen](https://github.com/yonaskolb/XcodeGen) beschreibt `project.yml` das Projekt als lesbaren Text; `xcodegen generate` erzeugt daraus `TheTap.xcodeproj`, und `xcodebuild` baut die App. Du änderst nur `project.yml`. Installation beim Nutzer: `brew install xcodegen`.

`project.yml` legt mindestens fest: Deployment Target macOS 26, Swift 6, die Bundle-ID, `LSUIElement = YES`, das URL-Schema `thetap`, kein App-Sandbox-Entitlement, Ad-hoc-Signierung (`CODE_SIGN_IDENTITY: "-"`) und die Abhängigkeit auf das lokale Package `Packages/BrewCheck`. In `Package.swift` steht ebenfalls macOS 26 als Plattform.

**Alltag in VS Code:** Der Nutzer öffnet den Repo-Ordner in VS Code und startet über „Terminal → Run Task …“ die Tasks aus `.vscode/tasks.json`: „Test“ (`swift test` im Package), „CLI“ (`swift run brewcheck-cli --no-update`), „App bauen“ (`scripts/build.sh`) und „App starten“ (`scripts/run.sh`). In `.vscode/settings.json` sorgt `swift.searchSubfoldersForPackages: true` dafür, dass die Swift-Erweiterung das Package im Unterordner findet; prüfe den Namen der Einstellung in der Doku der Erweiterung.

## Kernbibliothek BrewCheck

BrewCheck führt `brew update` und `brew outdated --json=v2 --greedy` aus und liefert eine sortierte Liste veralteter Pakete oder einen klar benannten Fehler. Die Bibliothek importiert weder SwiftUI noch AppKit.

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

public enum BrewCheckError: Error, Sendable {
    case brewNotFound(searched: [String])
    case commandFailed(command: [String], exitCode: Int32, output: String)
    case timedOut(command: [String], after: Duration)
    case invalidJSON(String)
    case cancelled
}
```

**brew finden (`BrewLocator`)**

1. Erst in `PATH` suchen, dann `/opt/homebrew/bin/brew` (Apple Silicon), dann `/usr/local/bin/brew` (Intel).
2. Ein Treffer muss existieren und ausführbar sein (`FileManager.isExecutableFile(atPath:)`).
3. `PATH` und die Dateiprüfung werden injiziert, damit Tests ohne echtes brew laufen.
4. Nichts gefunden → `brewNotFound` mit allen geprüften Pfaden.

**Befehle ausführen (`CommandRunner`)** – ein Protokoll, damit Tests einen Fake einsetzen können:

```swift
public protocol CommandRunner: Sendable {
    func run(_ executable: URL, arguments: [String],
             environment: [String: String], timeout: Duration) async throws -> CommandResult
}
public struct CommandResult: Sendable {
    public let exitCode: Int32
    public let stdout: Data
    public let stderr: Data
}
```

Die echte Umsetzung `ProcessRunner` nutzt `Foundation.Process` und muss:

- stdout und stderr getrennt und **parallel während des Laufs** lesen. Sonst hängt der Prozess, sobald ein Pipe-Puffer voll ist.
- bei Zeitüberschreitung erst `terminate()` (SIGTERM) senden, nach 5 Sekunden ohne Ende SIGKILL, dann `timedOut` werfen.
- nach einem Abbruch höchstens 5 Sekunden auf das Schließen der Pipes warten, weil Kindprozesse von brew sie offen halten können.
- den Prozess ebenfalls beenden und `cancelled` werfen, wenn die umgebende Swift-`Task` abgebrochen wird.
- nie den Main Thread blockieren (kein `waitUntilExit()` auf dem Main Actor).

**Umgebung für brew.** Eine aus dem Finder oder beim Login gestartete App erbt einen sehr kurzen `PATH`. Für jeden brew-Aufruf gilt deshalb:

- Prozessumgebung übernehmen, das Verzeichnis von brew vorne an `PATH` stellen, danach `/usr/bin:/bin:/usr/sbin:/sbin`.
- `HOMEBREW_NO_ENV_HINTS=1` setzen.
- Nur für `outdated` zusätzlich `HOMEBREW_NO_AUTO_UPDATE=1`, weil `update` direkt davor lief.

**Ablauf (`BrewChecker`).** Ein `actor`, damit nie zwei Prüfungen gleichzeitig laufen:

```swift
public actor BrewChecker {
    public init(runner: any CommandRunner = ProcessRunner(),
                locator: BrewLocator = BrewLocator(),
                updateTimeout: Duration = .seconds(600),
                outdatedTimeout: Duration = .seconds(120))
    public func outdated(runUpdate: Bool = true, greedy: Bool = true) async throws -> [OutdatedPackage]
}
```

1. brew finden.
2. Wenn `runUpdate`: `brew update`. Exit-Code ungleich 0 → `commandFailed` mit stdout und stderr als Text.
3. `brew outdated --json=v2`, plus `--greedy` wenn `greedy`. Nur stdout wird geparst; stderr enthält Warnungen und gehört in die Fehlermeldung.
4. Prüfe einmal am echten System, ob der Exit-Code 0 ist, auch wenn Pakete veraltet sind. Falls nicht: stdout trotzdem parsen, wenn es gültiges JSON ist.

**JSON parsen (`OutdatedParser`).** Das Format von `brew outdated --json=v2` sieht so aus (Werte nur als Beispiel; Feldnamen vor dem Schreiben des Parsers an echter Ausgabe prüfen):

```json
{
    "formulae": [
        {
            "name": "git",
            "installed_versions": ["2.46.0"],
            "current_version": "2.47.0",
            "pinned": false,
            "pinned_version": null
        }
    ],
    "casks": [
        {
            "name": "firefox",
            "installed_versions": ["130.0"],
            "current_version": "131.0"
        }
    ]
}
```

- `Codable` mit `CodingKeys` für die snake_case-Namen.
- Tolerant parsen: fehlendes `formulae` oder `casks` = leere Liste, fehlendes `pinned` = `false`, unbekannte Felder ignorieren, `installed_versions` auch als einzelnen String akzeptieren.
- Leere oder ungültige Ausgabe → `invalidJSON` mit den ersten 500 Zeichen.
- Sortierung: erst Formulae, dann Casks, jeweils nach Name mit `localizedStandardCompare`.

**Reine Regeln (`Policies`).** Alles, was die App entscheidet, aber ohne Oberfläche berechenbar ist, liegt hier als reine Funktion ohne Seiteneffekte:

- `isCheckDue(lastSuccess:interval:now:) -> Bool`
- `newlyOutdated(current:alreadyNotified:) -> [OutdatedPackage]` – ein Paket ist neu, wenn die Kombination aus Name, Art und `currentVersion` noch nicht gemeldet wurde. Angepinnte Pakete werden nie gemeldet.
- `pruneNotified(_:current:) -> Set<PackageKey>` – entfernt gemeldete Einträge für Pakete, die nicht mehr veraltet sind.
- `badgeCount(_:) -> Int` – zählt nur nicht angepinnte Pakete, weil `brew upgrade` angepinnte überspringt.

## CLI

Die CLI `brewcheck-cli` ist ein Entwicklerwerkzeug: Sie ruft `BrewChecker` auf und gibt das Ergebnis im Terminal aus, damit der Kern am echten System geprüft werden kann, bevor es eine App gibt.

- Aufruf im Ordner `Packages/BrewCheck`: `swift run brewcheck-cli`.
- Ohne Fremdbibliothek; die wenigen Optionen werden direkt aus `CommandLine.arguments` gelesen.
- `--no-update` überspringt `brew update` (schneller Testlauf).
- `--no-greedy` lässt `--greedy` weg.
- `--json` gibt die geparste Liste als JSON aus statt als Tabelle.
- Ausgabe ohne `--json`: Überschrift „Formulae“ und „Casks“, darunter je Zeile `name  installiert → neu`, angepinnte Pakete mit dem Zusatz „(angepinnt)“. Ohne veraltete Pakete: „Alles aktuell.“
- Fehler gehen auf stderr, mit derselben deutschen Kurzbeschreibung wie später in der App.
- Exit-Code 0 bei erfolgreicher Prüfung (egal ob Pakete veraltet sind), 1 bei Fehler, 2 bei falschen Optionen.

## Menüleisten-App

Die App zeigt ein Icon in der Menüleiste, das den Zustand auf einen Blick verrät, und öffnet beim Klick ein Panel mit der Paketliste. Sie prüft selbstständig, meldet neue Updates per Mitteilung und startet Upgrades im Terminal.

### Zustand (`AppState`)

`AppState` ist `@Observable` und `@MainActor` und die einzige Quelle der Wahrheit für die Oberfläche. Er hält die Phase, die letzte Paketliste, den Zeitpunkt der letzten erfolgreichen Prüfung, den letzten Fehler, die Zahl der Fehlversuche in Folge und ob gerade ein Upgrade läuft.

| Phase              | Icon in der Menüleiste                           | Kopfzeile im Panel                                |
| ------------------ | ------------------------------------------------ | ------------------------------------------------- |
| Noch nicht geprüft | `mug`                                            | „Noch nicht geprüft“                              |
| Prüft              | `arrow.triangle.2.circlepath`                    | „Prüfe auf Updates …“                             |
| Alles aktuell      | `mug`                                            | „Alles aktuell“                                   |
| Updates verfügbar  | `mug.fill` und die Zahl aus `badgeCount` daneben | „3 Updates verfügbar“                             |
| Offline            | `mug`                                            | „Offline – Prüfung folgt, sobald das Netz da ist“ |
| Fehler             | `exclamationmark.triangle`                       | Kurze Fehlerbeschreibung und „Log öffnen“         |

Die Namen sind SF Symbols; prüfe vor der Verwendung, dass sie unter macOS 26 existieren.

### Panel (`MenuBarExtra`, Stil `.window`)

1. Kopfzeile mit Phase und „Zuletzt geprüft: vor 12 Min.“ (`RelativeDateTimeFormatter`, deutsch).
2. Paketliste: erst Formulae, dann Casks; je Zeile Name und „installiert → neu“. Angepinnte Pakete grau mit Pin-Symbol. Ab etwa 12 Zeilen scrollt die Liste, statt das Panel wachsen zu lassen.
3. Knöpfe: „Alles aktualisieren“ (nur aktiv bei mindestens einem nicht angepinnten Paket; während eines Upgrades deaktiviert mit Text „Upgrade läuft im Terminal …“), „Jetzt prüfen“ (während einer Prüfung deaktiviert), „Einstellungen …“, „Beenden“.

### Prüfplan (`Scheduler`)

- **Beim Start:** erste Prüfung nach 10 Sekunden, weil das Netz direkt nach dem Login oft noch fehlt.
- **Regelmäßig:** `NSBackgroundActivityScheduler` mit `repeats = true` und dem Intervall aus den Einstellungen. Das System legt den Lauf in einen günstigen Moment und schont so den Akku.
- **Nach dem Aufwachen** (`NSWorkspace.didWakeNotification`): ist laut `isCheckDue` eine Prüfung fällig, nach 60 Sekunden prüfen.
- **Netzwerk:** `NWPathMonitor` beobachten. Offline wird nicht geprüft (Phase „Offline“); wieder online und fällig → prüfen.
- **Fehlschläge:** Eine automatische Prüfung, die scheitert (z. B. weil der Nutzer gerade selbst brew benutzt und eine Sperre hält), wird nach 15 Minuten still wiederholt. Erst nach 3 Fehlschlägen in Folge wechselt die Phase zu „Fehler“.
- **„Jetzt prüfen“** setzt den Fehlerzähler zurück und zeigt einen Fehler sofort an.
- Läuft bereits eine Prüfung, wird jede weitere Anfrage ignoriert.

### Mitteilungen (`Notifier`)

- Erlaubnis beim ersten Start mit `UNUserNotificationCenter.requestAuthorization(options: [.alert])` anfragen.
- Nach jeder erfolgreichen Prüfung `newlyOutdated` gegen die gespeicherte Menge gemeldeter Pakete (`UserDefaults`) aufrufen. Nur wenn das Ergebnis nicht leer ist, eine Mitteilung senden. Danach die Menge ergänzen und mit `pruneNotified` aufräumen.
- Titel: „3 Homebrew-Updates verfügbar“ (Zahl aus `badgeCount`). Text: bis zu drei Paketnamen, danach „und 2 weitere“.
- Eine `UNNotificationCategory` mit der Aktion „Alles aktualisieren“ startet das Upgrade wie der Knopf im Panel.
- `userNotificationCenter(_:willPresent:)` liefert `[.banner, .list]`, damit Mitteilungen auch erscheinen, während die App aktiv ist.
- Mitteilungen funktionieren nur in der gebündelten, signierten App, nicht über `swift run`.

### Upgrade (`UpgradeLauncher`)

1. Skript `thetap-upgrade.command` in `FileManager.default.temporaryDirectory` schreiben (bei jedem Upgrade neu) und die Rechte auf `0o755` setzen.
2. Mit `NSWorkspace.shared.open(_:)` öffnen. macOS startet es in der Standard-App für `.command`-Dateien, normalerweise Terminal.
3. Zustand „Upgrade läuft“ setzen.

Inhalt des Skripts. `<BREW>` ist der gefundene brew-Pfad, sicher in Anführungszeichen; `--greedy` nur, wenn die Einstellung aktiv ist:

```zsh
#!/bin/zsh
eval "$("<BREW>" shellenv)"
"<BREW>" upgrade --greedy --no-ask
echo
echo "Fertig. Dieses Fenster kann geschlossen werden."
open -g "thetap://recheck"
```

- `thetap://recheck` löst eine Prüfung **ohne** `brew update` aus (die Daten sind frisch) und beendet den Zustand „Upgrade läuft“.
- Kommt kein Recheck (Fenster vorher geschlossen), endet der Zustand nach 2 Stunden von selbst; die nächste reguläre Prüfung korrigiert die Liste.

### URL-Schema und App-Delegate

- `CFBundleURLTypes` mit dem Schema `thetap`, eingetragen über `project.yml`.
- Empfang über `@NSApplicationDelegateAdaptor` und `application(_:open:)` im `AppDelegate`. Unbekannte URLs ignorieren und loggen.
- Der `AppDelegate` ist zugleich `UNUserNotificationCenterDelegate`.

### Einstellungen

SwiftUI-`Settings`-Szene, geöffnet über `SettingsLink` im Panel. In einer App ohne Dock-Icon erscheint das Fenster leicht hinter anderen Fenstern; stell sicher, dass es nach vorne kommt (`NSApp.activate()`). Werte mit `@AppStorage` speichern.

- Prüfintervall: 1, 3, 6, 12 oder 24 Stunden, Standard 6.
- Beim Anmelden starten: `SMAppService.mainApp.register()` bzw. `unregister()`. Den Status bei jedem Öffnen aus `SMAppService.mainApp.status` lesen, weil der Nutzer ihn auch in den Systemeinstellungen ändern kann.
- Mitteilungen senden (an/aus). Sind sie in den Systemeinstellungen verboten, einen Hinweis mit Knopf dorthin zeigen.
- Casks mit eigenem Updater einbeziehen (`--greedy`), Standard an.
- Knopf „Log im Finder zeigen“.

## Fehlerbehandlung und Logging

Die App stürzt nie wegen brew ab und blockiert nie die Oberfläche; jeder Fehler wird geloggt und dem Nutzer kurz und verständlich angezeigt.

- **Systemlog:** `os.Logger` mit der Bundle-ID als Subsystem und den Kategorien `check`, `scheduler`, `upgrade`, `notifications`. Der Nutzer kann es in der App „Konsole“ ansehen.
- **Logdatei:** Fehlerdetails (Befehl, Exit-Code, die letzten 200 Zeilen Ausgabe) zusätzlich nach `~/Library/Logs/TheTap/thetap.log`. Ab 1 MB wird die Datei in `thetap.log.1` umbenannt und neu begonnen. Nicht `/tmp` verwenden, das leert macOS.
- **Meldungen in der Oberfläche:** eine Zeile auf Deutsch, die sagt, was zu tun ist. Beispiele:
    - `brewNotFound` → „Homebrew nicht gefunden. Erwartet unter /opt/homebrew oder /usr/local.“
    - `timedOut` → „brew hat nicht rechtzeitig geantwortet. Neuer Versuch folgt.“
    - `commandFailed` → „brew meldet einen Fehler. Details im Log.“
    - `invalidJSON` → „Unerwartete Antwort von brew. Details im Log.“
- **Keine sensiblen Daten** ins Log außer der brew-Ausgabe selbst; keine Umgebungsvariablen vollständig loggen.

## Teststrategie

Die Bibliothek BrewCheck wird vollständig automatisch getestet, ohne dass dabei echtes brew läuft; die App wird anhand einer Checkliste von Hand geprüft. Testframework ist Swift Testing (`import Testing`), ausgeführt mit `swift test` im Package.

**Parser** – Fixtures in `Tests/BrewCheckTests/Fixtures/`:

- `real.json`: echte Ausgabe des Nutzers. Er erzeugt sie mit `brew outdated --json=v2 --greedy > real.json`; du bittest ihn in Phase 1 darum.
- `empty.json` (beide Listen leer), `formulae-only.json`, `casks-only.json`, `pinned.json`, `extra-fields.json` (unbekannte Felder), `broken.json` (abgeschnitten), leere Datei.
- Geprüft werden Anzahl, Felder, Sortierung und der richtige Fehler.

**Locator** – mit injiziertem `PATH` und injizierter Dateiprüfung: Treffer in `PATH`, nur `/opt/homebrew`, nur `/usr/local`, gar nichts.

**ProcessRunner** – mit echten, harmlosen Systembefehlen:

- `/bin/echo` → Ausgabe und Exit-Code 0.
- `/bin/sh -c 'exit 3'` → Exit-Code 3.
- `/bin/sh -c 'echo out; echo err >&2'` → stdout und stderr getrennt.
- Große Ausgabe (mehrere MB, z. B. per `head -c` aus `/dev/zero`) → kein Hängen.
- `/bin/sleep 30` mit 1 Sekunde Timeout → `timedOut` nach wenigen Sekunden.
- Abbruch der Task während `/bin/sleep 30` → `cancelled`.

**BrewChecker** – mit einem `FakeRunner`, der vorbereitete Ergebnisse liefert: Update scheitert → kein Parsen und `commandFailed`; `runUpdate: false` → nur ein Aufruf; `greedy: false` → kein `--greedy` in den Argumenten; `HOMEBREW_NO_AUTO_UPDATE` nur beim `outdated`-Aufruf.

**Policies** – Tabellen von Eingaben und erwarteten Ergebnissen für `isCheckDue`, `newlyOutdated`, `pruneNotified` und `badgeCount`, inklusive angepinnter Pakete und neuer Versionen eines bereits gemeldeten Pakets.

**App** – keine UI-Tests. Stattdessen die Abnahmekriterien im Phasenplan als Checkliste mit dem Nutzer durchgehen.

## Phasenplan

Sieben Phasen, jede endet mit einem lauffähigen Stand und Kriterien, die der Nutzer selbst abhakt. Eine Phase beginnt erst, wenn die vorige abgehakt ist.

### Phase 0 – Werkzeuge und Repo

Xcode 26 aus dem App Store installieren, einmal öffnen und die Zusatzkomponenten installieren lassen; danach wird die Xcode-Oberfläche nicht mehr gebraucht. In VS Code die Swift-Erweiterung (Herausgeber: swiftlang) installieren. `brew install xcodegen`. Ein GitHub-Repo anlegen (Name frei, Vorschlag `thetap`) und per `git clone` auf den Mac holen. Die KI liefert im Chat die Inhalte für `.gitignore`, `docs/STATUS.md`, `.vscode/` und `.github/workflows/ci.yml`; der Nutzer legt die Dateien an und speichert diesen Plan als `docs/PLAN.md`.

- [ ] `swift --version` zeigt Swift 6 oder neuer
- [ ] `xcodegen --version` funktioniert
- [ ] Das Repo ist auf den Mac geklont, der Ordner öffnet sich in VS Code, die Swift-Erweiterung ist aktiv
- [ ] Der erste Commit mit `docs/PLAN.md` liegt auf GitHub; die GitHub-Actions-Prüfung ist angelegt und wird ab Phase 1 grün

### Phase 1 – Kernbibliothek mit Tests

Package `Packages/BrewCheck` anlegen; Datenmodell, `BrewLocator`, `ProcessRunner`, `OutdatedParser`, `BrewChecker` und `Policies` nach Spezifikation bauen. Den Nutzer um `real.json` bitten.

- [ ] `swift test` ist grün, alle Testgruppen aus der Teststrategie sind vorhanden
- [ ] Der Parser liest die echte `real.json` des Nutzers korrekt

### Phase 2 – CLI

`brewcheck-cli` nach Spezifikation.

- [ ] `swift run brewcheck-cli` zeigt dieselben Pakete wie `brew outdated --greedy`
- [ ] `--no-update`, `--no-greedy` und `--json` funktionieren
- [ ] Ohne Netz erscheint eine verständliche Fehlermeldung statt eines Absturzes

### Phase 3 – App-Gerüst

`project.yml`, App mit `MenuBarExtra`, `AppState`, Panel mit Liste sowie „Jetzt prüfen“ und „Beenden“. Noch keine Automatik und keine Mitteilungen.

- [ ] `scripts/build.sh` läuft ohne Fehler, lokal und in GitHub Actions
- [ ] Die VS-Code-Tasks „App bauen“ und „App starten“ funktionieren
- [ ] Die App startet ohne Dock-Icon und zeigt ihr Icon in der Menüleiste
- [ ] „Jetzt prüfen“ zeigt die echten Pakete; das Panel bleibt während der Prüfung bedienbar
- [ ] Das Icon zeigt die richtige Zahl

### Phase 4 – Upgrade und Recheck

`UpgradeLauncher`, URL-Schema `thetap://recheck`, Zustand „Upgrade läuft“.

- [ ] „Alles aktualisieren“ öffnet das Terminal und startet das Upgrade
- [ ] Nach dem Ende des Upgrades aktualisiert sich die Liste von selbst
- [ ] Angepinnte Pakete bleiben sichtbar, zählen aber nicht mit

### Phase 5 – Automatik und Mitteilungen

`Scheduler` mit Hintergrundplanung, Aufwachen, Netzwerkstatus und Wiederholung bei Fehlern; `Notifier`. Für Tests darf ein Debug-Build ein Intervall von 1 Minute anbieten.

- [ ] Beim ersten Start fragt macOS nach der Erlaubnis für Mitteilungen
- [ ] Ein neu veraltetes Paket ergibt genau eine Mitteilung; eine weitere Prüfung ohne Änderung ergibt keine
- [ ] Die Aktion „Alles aktualisieren“ in der Mitteilung startet das Upgrade
- [ ] WLAN aus → Phase „Offline“; WLAN wieder an → die fällige Prüfung folgt

### Phase 6 – Einstellungen, Login-Start, Feinschliff

Einstellungsfenster, `SMAppService`, Logdatei, App-Icon und ein Skript `scripts/install.sh`, das einen Release-Build erzeugt und nach `/Applications` kopiert.

- [ ] Die Einstellungen öffnen sich im Vordergrund; alle Werte bleiben nach einem Neustart der App erhalten
- [ ] „Beim Anmelden starten“ funktioniert nach Ab- und Anmelden
- [ ] Bei einem Fehler entsteht die Logdatei unter `~/Library/Logs/TheTap/`
- [ ] Die App liegt in `/Applications` und läuft eine Woche ohne Auffälligkeiten

## Annahmen und offene Punkte

Diese Punkte sind noch nicht mit dem Nutzer geklärt. Kläre sie spätestens in der genannten Phase und trage die Antwort hier ein.

- [x] **Name:** TheTap. App `TheTap.app`, URL-Schema `thetap`, Logordner `~/Library/Logs/TheTap/`.
- [x] **Bundle-ID:** `io.github.muunleit-projects.thetap`. Nie mehr ändern.
- [x] **macOS-Version:** macOS 26 auf dem Mac des Nutzers; Deployment Target macOS 26.
- [ ] **Terminal-App:** Annahme ist, dass `.command`-Dateien im Terminal (oder iTerm) geöffnet werden. In Phase 4 prüfen.
- [ ] **Signierung:** In Phase 5 prüfen, ob Mitteilungen und Login-Start mit Ad-hoc-Signierung zuverlässig funktionieren. Falls nicht: kostenloses „Personal Team“ mit der Apple-ID des Nutzers einrichten (einmalig in Xcode, als Ausnahme von der VS-Code-Regel).
- [ ] **CI-Runner:** In Phase 0 prüfen, welches GitHub-Actions-Image macOS 26 mit Xcode 26 bietet, und `ci.yml` darauf festlegen.
- [ ] **Standardwerte:** Prüfintervall 6 Stunden und `--greedy` an sind Vorschläge; der Nutzer kann sie nach einer Woche Alltag anpassen.

## Quellen

- [muunleit-projects/show_updates](https://github.com/muunleit-projects/show_updates) – Vorbild, insbesondere [checkupdates.go](https://raw.githubusercontent.com/muunleit-projects/show_updates/main/pkg/checkupdates/checkupdates.go)
- [Homebrew-Manpage](https://docs.brew.sh/Manpage) – Optionen von `outdated` und `upgrade` (`--json=v2`, `--greedy`, `--no-ask`) und Umgebungsvariablen
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
