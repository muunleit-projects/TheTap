# TheTap – Technische Spezifikation

27.10.2026 · gehört zu `docs/PLAN.md`

Diese Datei beschreibt, wie TheTap gebaut ist und sich verhält. Der Nutzer lädt sie hoch, wenn Code in `Packages/` oder `App/`, ein Skript oder `project.yml` geändert wird. Die Arbeitsregeln aus `PLAN.md` gelten auch hier. Code und Tests sind die genaue Quelle; diese Datei hält die Regeln und ihre Gründe fest. Weicht der Code ab, gilt der Code: Sprich den Widerspruch an und passe die Datei an. Dauerhafte Erkenntnisse aus Handproben stehen am Ende unter „Erprobtes Verhalten“.

## Projekt und Build

- **`project.yml`** legt fest: Deployment Target macOS 26, Swift 6, die Bundle-ID, `LSUIElement = YES`, das URL-Schema `thetap`, kein App-Sandbox-Entitlement, Ad-hoc-Signierung (`CODE_SIGN_STYLE: Manual`, `CODE_SIGN_IDENTITY: "-"`), `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` und die Abhängigkeit auf das lokale Package `Packages/BrewCheck`. Unter `info → properties` stehen `CFBundleShortVersionString: "$(MARKETING_VERSION)"` und `CFBundleVersion: "$(CURRENT_PROJECT_VERSION)"`; ohne sie schreibt XcodeGen fest `1.0` und `1` in `App/Info.plist` (geprüft im Quelltext von XcodeGen, `InfoPlistGenerator.swift`).
- **`scripts/build.sh [Debug|Release] [xcodebuild-Argumente]`:** `xcodegen generate`, dann `xcodebuild` mit `-derivedDataPath build`. Ergebnis unter `build/Build/Products/<Konfiguration>/TheTap.app`. Ohne Parameter Debug; so ruft es auch die CI auf.
- **`scripts/run.sh`:** Debug bauen, jede laufende TheTap beenden (SIGTERM, bis 5 Sekunden warten), den Debug-Build starten. Danach startet der Nutzer die installierte Kopie wieder mit `open /Applications/TheTap.app`.
- **`scripts/install.sh`:** `build.sh Release ONLY_ACTIVE_ARCH=YES` (nur die Architektur dieses Macs), laufende TheTap beenden, `/Applications/TheTap.app` löschen und per `ditto` neu kopieren, `codesign --verify --deep --strict`, starten. Setzt Schreibrechte in `/Applications` voraus.
- **`scripts/make-icons.sh`:** prüft `design/AppIcon-1024.png` auf 1024 × 1024 Pixel und erzeugt mit `sips` die zehn Dateien in `App/Assets.xcassets/AppIcon.appiconset` (`icon_16x16.png` bis `icon_512x512@2x.png`; die 1024er ist eine Kopie des Masters). Das Master liegt unter `design/`, weil XcodeGen alles unter `App/` in die App kopiert.
- **VS Code:** Tasks in `.vscode/tasks.json`: „Test“ (`swift test` in `Packages/BrewCheck`), „CLI“ (`swift run brewcheck-cli --no-update`), „App bauen“ (`scripts/build.sh`), „App starten“ (`scripts/run.sh`). Eine `.vscode/settings.json` gibt es bewusst nicht: `swift.searchSubfoldersForPackages` existiert in der Erweiterung nicht (vorhanden ist `swift.ignoreSearchingForPackagesInSubfolders`).
- **CI** (`.github/workflows/ci.yml`): Runner `macos-26`, `swift test` im Package, XcodeGen installieren, `scripts/build.sh`; bei jedem Push auf `main` und bei Pull Requests. Release-Workflow: siehe `docs/RELEASE.md`.

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
- **`BrewCheckError.logDetails`** (`BrewCheckError+LogDetails.swift`): englischer Logtext mit Befehl, Exit-Code und den letzten 200 Zeilen Ausgabe.
- **`UpgradeScript.content(brewPath:greedy:)`:** Text des `.command`-Skripts (siehe „Upgrade“). Der brew-Pfad steht in einfachen Anführungszeichen, ein `'` darin wird zu `'\''`.

**Reine Regeln (`Policies`).** Alles, was die App entscheidet, aber ohne Oberfläche berechenbar ist, liegt hier als reine Funktion ohne Seiteneffekte:

- `isCheckDue(lastSuccess:interval:now:) -> Bool` – fällig, wenn es noch keine erfolgreiche Prüfung gab, das Intervall abgelaufen ist oder `lastSuccess` in der Zukunft liegt (Uhr verstellt).
- `newlyOutdated(current:alreadyNotified:) -> [OutdatedPackage]` – ein Paket ist neu, wenn sein `PackageKey` noch nicht gemeldet wurde. Angepinnte Pakete werden nie gemeldet.
- `pruneNotified(_:current:) -> Set<PackageKey>` – entfernt gemeldete Einträge für Pakete, die nicht mehr in dieser Version veraltet sind.
- `badgeCount(_:) -> Int` – zählt nur nicht angepinnte Pakete, weil `brew upgrade` angepinnte überspringt.
- `failuresBeforeError = 3` und `showsFailure(consecutiveFailures:manual:) -> Bool` – eine manuelle Prüfung zeigt einen Fehler sofort, eine automatische erst ab 3 Fehlschlägen in Folge. `consecutiveFailures` zählt den aktuellen Fehlschlag mit.
- `notificationText(newPackages:badgeCount:) -> NotificationText` (Struktur mit `title` und `body`). Titel: „1 Homebrew-Update verfügbar“ bzw. „3 Homebrew-Updates verfügbar“ (Zahl aus `badgeCount`). Text: die Namen der neuen Pakete, bis drei als „git, node und wget“, mehr als „git, node, wget und 1 weiteres“ bzw. „… und 2 weitere“.

## CLI

`brewcheck-cli` ruft `BrewChecker` auf und dient nur zum Testen. Aufruf im Ordner `Packages/BrewCheck`: `swift run brewcheck-cli [--no-update] [--no-greedy] [--json]`; die Optionen werden ohne Fremdbibliothek aus `CommandLine.arguments` gelesen. Ausgabe als Tabelle (Formulae, dann Casks, je Zeile `name  installiert → neu`, angepinnte mit „(angepinnt)“, ohne Pakete „Alles aktuell.“) oder mit `--json` als JSON. Fehler gehen auf stderr: `userMessage` plus Befehl, Exit-Code und die letzten 20 Zeilen. Exit-Code 0 bei erfolgreicher Prüfung, 1 bei Fehler, 2 bei falschen Optionen.

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
| Fehler             | `exclamationmark.triangle`                       | Kurze Fehlerbeschreibung, Knopf „Log öffnen“      |

Die Namen sind SF Symbols und auf dem Mac des Nutzers bestätigt, ebenso `pin`. Prüfe jedes neue Symbol vor der Verwendung.

### Panel (`MenuBarExtra`, Stil `.window`)

1. Kopfzeile mit Phase und „Zuletzt geprüft: vor 12 Min.“ (`RelativeDateTimeFormatter`, deutsch, jede Minute neu berechnet).
2. Paketliste: erst Formulae, dann Casks; je Zeile Name und „installiert → neu“. Angepinnte Pakete grau mit Pin-Symbol. Ab 12 Zeilen scrollt die Liste, statt das Panel wachsen zu lassen.
3. Knöpfe: „Alles aktualisieren“ in eigener Zeile (nur aktiv bei mindestens einem nicht angepinnten Paket; während eines Upgrades deaktiviert mit Text „Upgrade läuft im Terminal …“); „Jetzt prüfen“ (während einer Prüfung und während eines Upgrades deaktiviert), daneben „Log öffnen“ nur in der Phase „Fehler“; in eigener Zeile „Einstellungen …“ (`SettingsLink`) und „Beenden“.

### Prüfplan (`Scheduler`)

Alle automatischen Auslöser rufen denselben Einstiegspunkt `AppState.checkIfDue()`. `checkIfDue()` startet eine Prüfung mit `brew update` nur, wenn alles zutrifft:

1. Es läuft keine Prüfung.
2. Es läuft kein Upgrade. Sonst stößt `brew update` mit `brew upgrade` im Terminal zusammen; geprüft wird nach dem Recheck oder beim nächsten Auslöser.
3. Das Netz ist da. Sonst Phase „Offline“.
4. `isCheckDue` sagt ja. Nach einem Fehlschlag bleibt `lastSuccess` unverändert, die Prüfung ist also weiter fällig; daraus ergibt sich die Wiederholung von selbst.

„Jetzt prüfen“ (`checkNow(runUpdate:manual:)` mit `manual: true`) übergeht Bedingung 4; der Knopf ist während eines Upgrades deaktiviert, Bedingung 2 gilt also auch dort. Der Recheck nach einem Upgrade beendet zuerst den Zustand „Upgrade läuft“ und übergeht Bedingung 4.

Jede Entscheidung (geprüft oder übersprungen, mit Grund) wird mit `os.Logger`, Kategorie `scheduler`, geloggt, damit sich der Prüfplan in der App „Konsole“ nachvollziehen lässt.

**Prüfintervall:** gespeichert in `UserDefaults` unter `checkInterval` in Sekunden, Standard 21600 (6 Stunden); das Einstellungsfenster schreibt denselben Schlüssel.

**Auslöser:**

- **Start:** 10 Sekunden nach dem Start, weil das Netz direkt nach dem Login oft noch fehlt.
- **Wecker:** `NSBackgroundActivityScheduler` mit `repeats = true`, Takt = Prüfintervall durch 3, höchstens 15 Minuten (ab 1 Stunde Prüfintervall gilt also immer die Grenze). Er prüft nicht selbst, sondern ruft nur `checkIfDue()`. Das System legt den Lauf in einen günstigen Moment und darf ihn etwas verschieben. Grund für den kurzen Takt: Liefe der Wecker im Prüfintervall und käme kurz davor eine manuelle Prüfung, folgte die nächste Prüfung erst nach fast dem doppelten Intervall. `Scheduler.restartActivity()` legt den Wecker neu an.
- **Aufwachen:** `NSWorkspace.didWakeNotification` (sie kommt über `NSWorkspace.shared.notificationCenter`, nicht über das normale Notification Center), danach 60 Sekunden warten und `checkIfDue()`.
- **Netz wieder da** (`NetworkMonitor`, `NWPathMonitor`): `AppState.networkChanged(isOnline:)` ruft `checkIfDue()`; ist nichts fällig, zurück zur vorigen Phase (`restorePhase()`).

**Fehlschläge:**

- Jeder Fehlschlag erhöht `consecutiveFailures`; eine erfolgreiche Prüfung setzt ihn auf 0.
- Ob ein Fehler sichtbar wird, entscheidet `Policies.showsFailure`. Bei einem stillen Fehlschlag bleiben die letzte Paketliste und die vorige Phase stehen; der nächste Wecker versucht es erneut. Typischer Grund: Der Nutzer benutzt gerade selbst brew.
- „Jetzt prüfen“ setzt den Zähler zurück und zeigt einen Fehler sofort. Der Recheck nach einem Upgrade zählt als automatische Prüfung, weil der Nutzer ihn nicht selbst auslöst.
- Ein Fehlschlag ohne Netz ergibt „Offline“, nicht „Fehler“.

**Recheck nach dem Upgrade** (`thetap://recheck`): beendet „Upgrade läuft“ und prüft ohne `brew update`. Läuft gerade eine Prüfung, wird der Recheck vorgemerkt (`recheckPending`) und direkt nach ihrem Ende ausgeführt, statt verloren zu gehen.

### Mitteilungen (`Notifier`)

- Der `AppDelegate` ist `UNUserNotificationCenterDelegate` und setzt sich in `applicationWillFinishLaunching(_:)` als Delegate. Apple verlangt, dass das vor dem Ende des Starts geschieht.
- Erlaubnis beim Start mit `UNUserNotificationCenter.requestAuthorization(options: [.alert])` anfragen.
- Nach jeder erfolgreichen Prüfung ruft `AppState` `notifier.handle(_:)`: `newlyOutdated` gegen die gespeicherte Menge gemeldeter Pakete. Ist das Ergebnis nicht leer, die Einstellung „Mitteilungen senden“ an und die Erlaubnis da, eine Mitteilung mit Titel und Text aus `Policies.notificationText` senden.
- Danach die Menge immer fortschreiben (neue Schlüssel ergänzen, mit `pruneNotified` aufräumen), und zwar vor dem ersten `await`. Das gilt auch, wenn keine Mitteilung gesendet wurde (nicht erlaubt oder in den Einstellungen aus; Log: `Not sending: notifications are switched off in the settings`); sonst käme beim Einschalten eine Mitteilung über längst bekannte Pakete.
- Speicherort: `UserDefaults`, Schlüssel `notifiedPackages`, als JSON-codiertes Array von `PackageKey`. Zum Testen leeren mit `defaults delete io.github.muunleit-projects.thetap notifiedPackages` (App vorher beenden).
- Kategorie `thetap.updates` mit der Aktion `thetap.upgrade` („Alles aktualisieren“, `Notifier.registerCategories()`); sie startet das Upgrade wie der Knopf im Panel. Ist gerade kein Upgrade möglich, passiert nichts.
- `userNotificationCenter(_:willPresent:)` liefert `[.banner, .list]`, damit Mitteilungen auch erscheinen, während die App aktiv ist.
- Mitteilungen funktionieren nur in der gebündelten, signierten App, nicht über `swift run`.

### Upgrade (`UpgradeLauncher`)

`UpgradeLauncher` schreibt den Text aus `UpgradeScript.content` bei jedem Upgrade neu als `thetap-upgrade.command` in `FileManager.default.temporaryDirectory`, setzt die Rechte auf `0o755`, öffnet die Datei mit `NSWorkspace.shared.open(_:)` in der Terminal-App und setzt „Upgrade läuft“. Fehler kommen als `UpgradeLaunchError` mit deutschem `userMessage` und der Ursache in `description`. Das Skript (`<BREW>` ist der brew-Pfad in einfachen Anführungszeichen; `--greedy` nur, wenn die Einstellung aktiv ist):

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
- Der `AppDelegate` hält `AppState`, `NetworkMonitor` und den Scheduler und ist zugleich `UNUserNotificationCenterDelegate`.
- Zwei Kopien mit derselben Bundle-ID (Debug-Build in `build/`, installierte App in `/Applications` oder ein Download) dürfen nie gleichzeitig laufen, sonst landet `thetap://recheck` womöglich in der falschen. `scripts/run.sh` beendet jede laufende TheTap.

### Einstellungen

SwiftUI-`Settings`-Szene (`App/Views/SettingsView.swift`, `Form` mit `.formStyle(.grouped)`, Breite 460), geöffnet über `SettingsLink` („Einstellungen …“) im Panel. In einer App ohne Dock-Icon erscheint das Fenster leicht hinter anderen Fenstern; `NSApp.activate()` in `onAppear` bringt es nach vorne, das Panel bleibt dabei offen. Werte werden mit `@AppStorage` gespeichert; die Schlüssel stehen als `nonisolated static` in `AppState` und `Notifier`, damit Swift 6 sie im View zulässt.

- **Beim Anmelden starten** (Abschnitt „Start“ ganz oben): `SMAppService.mainApp.register()` bzw. `unregister()`. Der Schalter ist über eine eigene `Binding` an, wenn `SMAppService.mainApp.status` `.enabled` oder `.requiresApproval` ist. Bei `.requiresApproval` erscheinen ein Hinweis und der Knopf „Anmeldeobjekte öffnen“ (`SMAppService.openSystemSettingsLoginItems()`), bei `.notFound` ein Hinweis. Fehler von `register()`/`unregister()` erscheinen als rote deutsche Zeile und im Systemlog (Kategorie `settings`). Der Status wird bei `onAppear` und bei jedem Aktivwerden der App neu gelesen, weil der Nutzer ihn auch in den Systemeinstellungen ändern kann. Nur mit der Kopie in `/Applications` einschalten: Bei zwei Kopien mit derselben Bundle-ID ist nicht verlässlich, welche beim Anmelden startet.
- **Prüfintervall:** 1, 3, 6, 12 oder 24 Stunden, Standard 6 (als „Standard“ beschriftet), gespeichert unter `checkInterval` in Sekunden. Ändert sich der Wert, ruft das Fenster `AppState.checkIntervalChanged()`; der `AppDelegate` hat dort `scheduler.restartActivity()` als Rückruf (`onCheckIntervalChange`) eingetragen, der Wecker wird also ohne Neustart neu angelegt. Ein Wert außerhalb der Auswahl (z. B. 180 zum Testen) gilt weiter, wird im Auswahlfeld aber nicht angezeigt.
- **Casks mit eigenem Updater einbeziehen** (`--greedy`): `includeGreedy`, Standard an. `AppState.includeGreedy` liest `UserDefaults` bei jedem Zugriff und steuert Prüfung (`BrewChecker.outdated(greedy:)`) und Upgrade (`UpgradeLauncher.start(greedy:)`), jeweils ab dem nächsten Aufruf.
- **Mitteilungen senden:** `notificationsEnabled`, Standard an (`Notifier.isEnabled`). Erlaubt macOS keine Mitteilungen (`Notifier.isAllowedBySystem()`), zeigt das Fenster einen Hinweis und den Knopf „Systemeinstellungen öffnen“ (`x-apple.systempreferences:com.apple.Notifications-Settings.extension`, Rückfall auf `x-apple.systempreferences:`); der Status wird beim Öffnen und bei jedem Aktivwerden der App neu gelesen.
- **Log im Finder zeigen:** markiert `thetap.log` im Finder, öffnet sonst den Ordner, falls er existiert.

## Fehlerbehandlung und Logging

Die App stürzt nie wegen brew ab und blockiert nie die Oberfläche; jeder Fehler wird geloggt und dem Nutzer kurz und verständlich angezeigt.

- **Systemlog:** `os.Logger` mit der Bundle-ID als Subsystem und den Kategorien `check`, `scheduler`, `upgrade`, `notifications` und `settings`. Der Nutzer sieht es in der App „Konsole“ (nach dem Subsystem filtern) oder im Terminal (siehe „Handproben“).
- **Logdatei:** `App/LogFile.swift` (`@MainActor`, `write(_:date:)`) schreibt Fehlerdetails nach `~/Library/Logs/TheTap/thetap.log`: Zeitstempel (ISO 8601, lokale Zeit), Kopfzeile `Check failed (N in a row, manual: …, shown: …)`, darunter `BrewCheckError.logDetails`, nach jedem Eintrag eine Leerzeile. Geloggt wird jeder gezählte Fehlschlag, auch ein stiller; ein Fehlschlag ohne Netz („Offline“) nicht. Fehler beim Starten des Upgrades stehen als `Upgrade could not be started` mit `Upgrade launch failed: …` in derselben Datei. Ab 1 MB (`maxBytes`) wird die Datei vor dem Schreiben in `thetap.log.1` umbenannt (eine ältere `.1` wird ersetzt). Nicht `/tmp` verwenden, das leert macOS. Schreibfehler landen nur im Systemlog (Kategorie `check`).
- **„Log öffnen“:** Knopf im Panel, nur in der Phase „Fehler“; öffnet die Logdatei mit `NSWorkspace.shared.open` (in der App „Konsole“).
- **Meldungen in der Oberfläche:** eine Zeile auf Deutsch, die sagt, was zu tun ist (`BrewCheckError.userMessage`):
  - `brewNotFound` → „Homebrew nicht gefunden. Erwartet unter /opt/homebrew oder /usr/local.“
  - `timedOut` → „brew hat nicht rechtzeitig geantwortet. Neuer Versuch folgt.“
  - `commandFailed` → „brew meldet einen Fehler. Details im Log.“
  - `invalidJSON` → „Unerwartete Antwort von brew. Details im Log.“
  - `cancelled` → „Die Prüfung wurde abgebrochen.“
- **Keine sensiblen Daten** ins Log außer der brew-Ausgabe selbst; keine Umgebungsvariablen vollständig loggen. Bekannte Ausnahme, vom Nutzer so belassen (22.10.2026): Der Eintrag zu `brewNotFound` listet alle durchsuchten Ordner, also praktisch den `PATH` der App mit Pfaden aus dem Home-Verzeichnis (die README weist darauf hin).

## Teststrategie

Die Bibliothek BrewCheck wird vollständig automatisch getestet, ohne dass dabei echtes brew läuft; die App wird anhand der Abnahmekriterien von Hand geprüft (keine UI-Tests). Testframework ist Swift Testing (`import Testing`), ausgeführt mit `swift test` im Package.

Jede Komponente hat eine eigene Testdatei: `OutdatedParserTests` (Fixtures `real.json` als echte Ausgabe des Nutzers, `empty.json`, `formulae-only.json`, `casks-only.json`, `pinned.json`, `extra-fields.json`, `broken.json`, `blank.json` als leere Datei), `BrewLocatorTests` (injizierter `PATH`), `ProcessRunnerTests` (echte, harmlose Systembefehle: Exit-Codes, getrennte Ausgaben, mehrere MB, Timeout, Abbruch), `BrewCheckerTests` (mit `FakeRunner`: Argumente, Umgebung, Fehlerfälle), `PoliciesTests` (Tabellen inklusive angepinnter Pakete und neuer Versionen), `UpgradeScriptTests`, `ErrorMessageTests`, `LogDetailsTests` und `ModelsTests`. Neue Regeln bekommen ihre Tests in der passenden Datei. Code in `App/` (z. B. `LogFile`) liegt außerhalb des Packages und wird von Hand geprüft.

- `real.json` enthält nur ein Cask (`losslesscut`) und keine Formulae; Formulae und angepinnte Pakete kommen aus selbst geschriebenen Fixtures.
- Tests dürfen nie von der Umgebung der Maschine abhängen. Gegenprobe: `HOMEBREW_NO_AUTO_UPDATE=1 swift test` muss ebenfalls grün sein.
- Die Testausgabe zählt weniger Suites als Testdateien, weil `BrewLocatorTests` und `ModelsTests` kein `@Suite` haben; das ist harmlos. `Target Platform: arm64e-apple-macos14.0` in der Ausgabe ist nur eine Anzeige des Test-Frameworks.

## Erprobtes Verhalten

Auf dem Mac des Nutzers oder in der CI beobachtet. Neue dauerhafte Erkenntnisse kommen hierher, nicht nach `STATUS.md`.

**brew**

- `brew upgrade` kennt `--no-ask` (kurz `-y`) und `--greedy` (kurz `-g`).
- Ohne Netz scheitert `brew update` mit Exit-Code 1 und „Could not resolve host“; die App zeigt dann „Offline“, sofern `NWPathMonitor` das Netz als weg meldet.
- Ohne `HOMEBREW_NO_AUTO_UPDATE` aktualisiert `brew outdated` die API-Daten selbst; ein CLI-Lauf mit `--no-update` zeigt deshalb ggf. weniger Pakete als ein manueller `brew outdated`.

**macOS**

- `NWPathMonitor` meldet einen Wechsel oft mehrfach kurz nacheinander. Der `AppDelegate` loggt jede Meldung; `AppState.networkChanged` ignoriert eine Meldung ohne Statuswechsel.
- `NSBackgroundActivityScheduler` verschiebt den Wecker in beide Richtungen: Bei 60 Sekunden Takt kamen Ticks nach 53 bis 75 Sekunden (der erste nach 108); bei 900 Sekunden feuerte er schon direkt nach dem Start, vor dem Start-Trigger, der dann richtigerweise `Skipped: not due yet` loggt. Nach dem Ruhezustand begann eine Prüfung teils schon vor dem Wake-Trigger.
- `.command`-Dateien öffnen sich in der Terminal-App (nicht iTerm). Terminal schließt das Fenster, sobald die Shell sauber endet.
- Mitteilungs-Erlaubnis beim ersten Start (22.10.2026, ad hoc signierter Debug-Build): macOS zeigt ein Banner „Mitteilungen von „TheTap““. Ein Klick darauf öffnet die Systemeinstellungen (Mitteilungen → TheTap), dort „Mitteilungen erlauben“ einschalten. Die Anfrage lief rund 43 Sekunden und endete mit „Notifications are not allowed for this application“; danach war ein Neustart der App nötig (Ursache ungeklärt, obwohl `notificationSettings()` bei jeder Mitteilung neu gelesen wird). Die Erlaubnis bleibt nach einem Neubau, nach `scripts/install.sh` und beim Wechsel auf die heruntergeladene Runner-Kopie erhalten. Die Aktion „Alles aktualisieren“ erscheint als Knopf in der Mitteilung in der Mitteilungszentrale.
- Login-Start mit Ad-hoc-Signierung funktioniert für die Kopie in `/Applications`: Banner „Anmeldeobjekt hinzugefügt …“, Eintrag unter Systemeinstellungen → Allgemein → Anmeldeobjekte & Erweiterungen; bei aktivem Login-Item loggt die App `Login item status: SMAppServiceStatus(rawValue: 1)` (= `.enabled`).
- `NSWorkspace.shared.open` öffnet die Logdatei in der App „Konsole“. Die URL `x-apple.systempreferences:com.apple.Notifications-Settings.extension` öffnet unter macOS 26 die Seite „Mitteilungen“.
- Freigabe einer heruntergeladenen Ad-hoc-App: Ablauf mit allen Dialogtexten in der README unter „Erster Start: Freigabe in macOS“; `xattr -dr com.apple.quarantine /Applications/TheTap.app` ersetzt die Freigabe. Einstellung „Apps erlauben von“ beim Nutzer: „App Store & Bekannte Entwicklungsteams“.
- `lsregister` liegt unter `/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister`; der Dump zeigte vor dem Aufräumen vier Pfade für `TheTap.app` (`/Applications`, Papierkorb, `build/…/Debug`, `build/…/Release`).

**Swift 6 und Toolchain**

- Top-Level-`await` ist in `main.swift` erlaubt; `exit(n)` beendet die CLI mit dem Exit-Code.
- Eine `nonisolated` Funktion darf nicht auf Konstanten einer `@MainActor`-Klasse zugreifen („main actor-isolated static property … can not be referenced from a nonisolated context“). Deshalb sind `categoryIdentifier`, `upgradeActionIdentifier` und `enabledKey` in `Notifier` sowie `checkIntervalKey`, `includeGreedyKey` und `defaultCheckInterval` in `AppState` `nonisolated static`.
- Der Block von `NSBackgroundActivityScheduler.schedule` ist `@Sendable [weak self] completion in …`; `completion(.finished)` wird direkt im Block aufgerufen, nur `trigger` läuft in einer `Task { @MainActor … }`. Baut mit Swift 6.4 und 6.3.3.
- `Notifier` nutzt `UNUserNotificationCenter.current()` als lokale Konstante in den `async`-Methoden; die Delegate-Methoden im `AppDelegate` sind `nonisolated async` und springen für die Aktion per `await` auf eine `@MainActor`-Methode.
- Die `xcodebuild`-Meldung „Using the first of multiple matching destinations“ ist harmlos.
- `install.sh` baut nur `arm64`; Universal-Builds (Apple Silicon und Intel) entstehen nur auf dem Runner.

**Handproben**

- Systemlog live: `log stream --predicate 'subsystem == "io.github.muunleit-projects.thetap"'`; rückwirkend `log show --last 5m --predicate …`. `Logger.notice` erscheint ohne weitere Optionen. Typische Zeilen: `Trigger: startup` bzw. `Trigger: timer`, `Starting check`, `Skipped: not due yet`, `Check interval changed to … s`, `Timer set: tick every 900 s`, `Authorization granted`, `Not sending: notifications are not allowed (1 new)`, `Launch at login registered`/`unregistered`, `Login item status: …`. Erfolgreiche Prüfungen loggt `AppState` nicht selbst; sichtbar sind sie nur über die Zeilen der Kategorie `notifications`.
- Fehlschlag erzeugen: erst `which -a brew` (nur ein Treffer), dann `mv /opt/homebrew/bin/brew /opt/homebrew/bin/brew.off` → „Homebrew nicht gefunden …“. Zurück mit `mv /opt/homebrew/bin/brew.off /opt/homebrew/bin/brew`; danach muss `which brew` wieder `/opt/homebrew/bin/brew` zeigen.
- Rotation: `head -c 1100000 /dev/zero | tr '\0' 'x' > ~/Library/Logs/TheTap/thetap.log`, dann einen Fehler auslösen und `ls -l ~/Library/Logs/TheTap/` ansehen.
- Prüfplan schneller testen: App beenden, `defaults write io.github.muunleit-projects.thetap checkInterval -float 180` (3 Minuten); zurück mit `defaults delete io.github.muunleit-projects.thetap checkInterval`.
- Welche Kopie läuft: `pgrep -fl TheTap` zeigt den Pfad; `lipo -archs /Applications/TheTap.app/Contents/MacOS/TheTap` ergibt lokal gebaut `arm64`, heruntergeladen `x86_64 arm64`. Signatur: `codesign -dv /Applications/TheTap.app` mit `Signature=adhoc` und `TeamIdentifier=not set`.
