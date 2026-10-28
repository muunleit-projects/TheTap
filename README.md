# TheTap

[![CI](https://github.com/muunleit-projects/TheTap/actions/workflows/ci.yml/badge.svg)](https://github.com/muunleit-projects/TheTap/actions/workflows/ci.yml)

TheTap ist eine Menüleisten-App für macOS, die im Hintergrund prüft, welche Homebrew-Pakete veraltet sind. Sie meldet neue Updates per Mitteilung und startet auf Klick alle Upgrades im Terminal.

> **Stand:** TheTap ist noch in Entwicklung, läuft aber schon im Alltag. Der erste veröffentlichte Download steht noch aus; bis dahin baust du die App selbst aus dem Quellcode (siehe [Selbst bauen](#selbst-bauen)).

Die Idee stammt von [show_updates](https://github.com/muunleit-projects/show_updates), einer Go-App, die beim Anmelden `brew update` und `brew outdated` ausführt und das Ergebnis in einem Fenster zeigt. TheTap setzt die Idee in Swift neu um: Statt eines Fensters gibt es ein Icon in der Menüleiste, das selbstständig prüft.

## Funktionen

- **Überblick in der Menüleiste:** Das Icon zeigt den Zustand und die Zahl der verfügbaren Updates.
- **Paketliste:** Formulae und Casks mit installierter und neuer Version. Angepinnte Pakete erscheinen grau mit Pin-Symbol und zählen nicht mit, weil `brew upgrade` sie überspringt.
- **Automatische Prüfung:** kurz nach dem Start, danach im eingestellten Intervall (Standard: alle 6 Stunden), nach dem Aufwachen aus dem Ruhezustand und sobald das Netz wieder da ist.
- **Mitteilungen nur bei Neuem:** TheTap meldet sich nur, wenn neue veraltete Pakete dazukommen, nicht bei jeder Prüfung. Das Upgrade lässt sich direkt aus der Mitteilung starten.
- **Upgrade im Terminal:** „Alles aktualisieren“ startet `brew upgrade` in der Terminal-App, damit Casks, die ein Passwort brauchen, nachfragen können. Danach aktualisiert sich die Liste von selbst.
- **Gelassen bei Störungen:** Ohne Netz zeigt TheTap „Offline“ statt eines Fehlers. Einzelne Fehlschläge automatischer Prüfungen bleiben still; ein Fehler erscheint erst ab dem dritten in Folge. Details landen in einer Logdatei.
- **Einstellungen** für Prüfintervall, Casks mit eigenem Updater, Mitteilungen und den Start beim Anmelden.
- **Keine Fremdbibliotheken:** nur Apple-Frameworks und die Swift-Standardbibliothek.

## Bedienung

### Icon in der Menüleiste

TheTap hat kein Dock-Icon, sondern lebt nur in der Menüleiste.

| Icon                    | Bedeutung                                                          |
| ----------------------- | ------------------------------------------------------------------ |
| Tasse                   | Noch nicht geprüft, alles aktuell oder offline                     |
| Gefüllte Tasse mit Zahl | Updates verfügbar; die Zahl zählt angepinnte Pakete nicht mit      |
| Kreisende Pfeile        | Prüfung läuft                                                      |
| Warndreieck             | Fehler; die Beschreibung steht im Panel, die Details stehen im Log |

### Panel

Ein Klick auf das Icon öffnet das Panel:

- **Kopfzeile** mit dem Zustand (z. B. „3 Updates verfügbar“) und dem Zeitpunkt der letzten Prüfung („Zuletzt geprüft: vor 12 Min.“).
- **Liste** der veralteten Pakete, erst Formulae, dann Casks, jeweils als `installiert → neu`.
- **Alles aktualisieren:** startet das Upgrade im Terminal. Der Knopf ist nur aktiv, wenn mindestens ein nicht angepinntes Paket veraltet ist.
- **Jetzt prüfen:** aktualisiert sofort die Homebrew-Daten und prüft. Ein Fehler wird dabei sofort angezeigt.
- **Log öffnen:** erscheint nur bei einem Fehler.
- **Einstellungen …** und **Beenden**.

### Upgrade

„Alles aktualisieren“ legt ein kleines Skript im temporären Ordner an und öffnet es in der Terminal-App. Das Skript führt `brew upgrade --greedy --no-ask` aus (`--greedy` nur, wenn „Casks mit eigenem Updater einbeziehen“ eingeschaltet ist). Am Ende meldet es sich über `thetap://recheck` bei TheTap, die Liste wird neu geladen, und das Fenster wartet auf einen Tastendruck, damit du die Ausgabe von brew in Ruhe lesen kannst.

Solange das Upgrade läuft, startet TheTap keine eigene Prüfung, damit sich `brew update` und `brew upgrade` nicht in die Quere kommen. Schließt du das Terminal-Fenster vor dem Ende, endet der Zustand „Upgrade läuft“ nach zwei Stunden von selbst.

## Voraussetzungen

- macOS 26 (Tahoe) oder neuer
- [Homebrew](https://brew.sh/), installiert unter `/opt/homebrew` (Apple Silicon) oder `/usr/local` (Intel)

Zum [Selbstbauen](#selbst-bauen) kommen hinzu:

- Xcode 26 oder neuer. Gebraucht werden nur Compiler, SDK und `xcodebuild`; die Oberfläche von Xcode musst du nicht öffnen.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Herunterladen und installieren

Fertig gebaute Versionen stehen unter [Releases](https://github.com/muunleit-projects/TheTap/releases). Sie enthalten Code für Apple Silicon und Intel; getestet ist bisher nur Apple Silicon. Vorabversionen sind dort als „Pre-release“ markiert.

1. Die neueste Datei `TheTap-….zip` herunterladen.
2. Die ZIP im Finder doppelklicken. Daneben entsteht `TheTap.app`.
3. `TheTap.app` in den Ordner „Programme“ ziehen.

### Erster Start: Freigabe in macOS

TheTap ist ad hoc signiert und nicht notarisiert, weil es kein Apple-Developer-Konto gibt. Deshalb blockiert macOS die heruntergeladene App beim ersten Start, bis du sie freigibst. Die folgenden Texte stammen von macOS 26 auf Deutsch; in anderen Sprachen lauten sie anders.

1. `TheTap.app` in „Programme“ doppelklicken. macOS meldet „„TheTap“ nicht geöffnet“ („Apple konnte nicht überprüfen, ob „TheTap“ frei von Schadsoftware ist …“). Klicke auf **Fertig**, nicht auf „In den Papierkorb legen“.
2. Öffne die Systemeinstellungen → **Datenschutz & Sicherheit** und scrolle zum Abschnitt „Sicherheit“. Dort steht „„TheTap“ wurde blockiert, um deinen Mac zu schützen.“ Klicke auf **Dennoch öffnen**.
3. Im Dialog „„TheTap“ öffnen?“ klickst du erneut auf **Dennoch öffnen**.
4. macOS fragt nach Admin-Benutzernamen und Passwort. Gib sie ein und bestätige mit **OK**. TheTap startet.

Ab dann startet die App ohne Warnung.

Alternativ geht es im Terminal. Der Befehl entfernt die Markierung „aus dem Internet geladen“, danach startet die App ohne Warnung:

```sh
xattr -dr com.apple.quarantine /Applications/TheTap.app
```

### Aktualisieren

TheTap über „Beenden“ im Panel schließen, die neue Version herunterladen und die alte in „Programme“ ersetzen. In einem Test blieben beim Ersetzen einer lokal gebauten Kopie durch `TheTap-0.1.0-test.1` die Mitteilungs-Erlaubnis und der Eintrag in den Anmeldeobjekten erhalten. Ob die Freigabe in „Datenschutz & Sicherheit“ bei einer neueren heruntergeladenen Version erneut nötig ist, ist noch nicht geprüft.

## Selbst bauen

```sh
git clone https://github.com/muunleit-projects/TheTap.git
cd TheTap
scripts/install.sh
```

`install.sh` baut die Release-Version für die Architektur deines Macs, beendet eine laufende TheTap, ersetzt `/Applications/TheTap.app`, prüft die Signatur und startet die App. Dafür brauchst du Schreibrechte in `/Applications`. Eine selbst gebaute Kopie braucht keine Freigabe in „Datenschutz & Sicherheit“.

**Aktualisieren:** Neuesten Stand holen und das Skript erneut ausführen:

```sh
git pull
scripts/install.sh
```

## Erster Start

1. Das Tassen-Icon erscheint in der Menüleiste. Etwa 10 Sekunden nach dem Start läuft die erste Prüfung.
2. macOS fragt mit dem Banner „Mitteilungen von „TheTap““ nach der Erlaubnis für Mitteilungen. Ein Klick auf das Banner öffnet die Systemeinstellungen; schalte dort „Mitteilungen erlauben“ ein. Kommen danach keine Mitteilungen, beende TheTap einmal über „Beenden“ und starte sie neu.
3. Soll TheTap bei jeder Anmeldung starten: Panel → „Einstellungen …“ → „Beim Anmelden starten“ einschalten.

## Einstellungen

Das Fenster öffnest du im Panel über „Einstellungen …“. Alle Werte bleiben nach einem Neustart erhalten.

| Einstellung                           | Standard       | Wirkung                                                                                                                                               |
| ------------------------------------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Beim Anmelden starten                 | aus            | Trägt TheTap in die Anmeldeobjekte von macOS ein. Wartet macOS auf deine Freigabe, führt der Knopf „Anmeldeobjekte öffnen“ dorthin.                   |
| Prüfintervall                         | Alle 6 Stunden | Jede Stunde, alle 3, 6 oder 12 Stunden oder einmal täglich. Eine Änderung wirkt sofort, ohne Neustart.                                                |
| Casks mit eigenem Updater einbeziehen | an             | Entspricht `brew --greedy` und gilt für Prüfung und Upgrade, jeweils ab dem nächsten Aufruf.                                                          |
| Mitteilungen senden                   | an             | Schaltet die Mitteilungen von TheTap ab. Sind Mitteilungen in macOS nicht erlaubt, zeigt das Fenster einen Knopf, der die Systemeinstellungen öffnet. |
| Log im Finder zeigen                  | –              | Markiert die Logdatei im Finder.                                                                                                                      |

„Beim Anmelden starten“ solltest du nur mit der Kopie in `/Applications` einschalten. Gibt es mehrere Kopien der App, ist nicht sicher, welche macOS beim Anmelden startet.

## Fehlersuche

### Meldungen im Panel

| Meldung                                                                  | Bedeutung                                                                                                             |
| ------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| „Homebrew nicht gefunden. Erwartet unter /opt/homebrew oder /usr/local.“ | `brew` liegt an keinem der erwarteten Orte.                                                                           |
| „brew hat nicht rechtzeitig geantwortet. Neuer Versuch folgt.“           | Zeitlimit überschritten (10 Minuten für `brew update`, 2 Minuten für `brew outdated`).                                |
| „brew meldet einen Fehler. Details im Log.“                              | brew ist mit einem Fehler beendet worden, z. B. weil du gerade selbst einen brew-Befehl ausführst oder das Netz hakt. |
| „Unerwartete Antwort von brew. Details im Log.“                          | Die Ausgabe von `brew outdated` war kein gültiges JSON.                                                               |

### Logdatei

TheTap schreibt Fehlerdetails nach `~/Library/Logs/TheTap/thetap.log`: zu jedem Fehlschlag den Befehl, den Exit-Code und die letzten 200 Zeilen der Ausgabe von brew, dazu Fehler beim Start des Upgrades. Ab 1 MB wird die Datei in `thetap.log.1` umbenannt und neu begonnen. Du öffnest sie über „Log öffnen“ im Panel oder findest sie über „Log im Finder zeigen“ in den Einstellungen.

Der Eintrag zu „Homebrew nicht gefunden“ listet alle durchsuchten Ordner auf, also praktisch den `PATH` der App samt Pfaden aus deinem Benutzerordner. Denk daran, bevor du das Log öffentlich teilst.

### Systemlog

Was TheTap entscheidet (etwa, ob eine Prüfung startet oder warum sie übersprungen wird), steht im Systemlog. Live mitlesen im Terminal:

```sh
log stream --predicate 'subsystem == "io.github.muunleit-projects.thetap"'
```

Rückwirkend, z. B. für die letzte halbe Stunde:

```sh
log show --last 30m --predicate 'subsystem == "io.github.muunleit-projects.thetap"'
```

Die Kategorien sind `check`, `scheduler`, `upgrade`, `notifications` und `settings`. Alternativ zeigt die App „Konsole“ dieselben Einträge, wenn du nach dem Subsystem filterst.

### Werte zurücksetzen

Beende TheTap vorher über „Beenden“.

```sh
# Prüfintervall auf den Standard (6 Stunden) zurücksetzen
defaults delete io.github.muunleit-projects.thetap checkInterval

# Bereits gemeldete Pakete vergessen; die nächste Prüfung meldet alle veralteten Pakete neu
defaults delete io.github.muunleit-projects.thetap notifiedPackages
```

## Entwicklung

### Bauen und starten

```sh
scripts/build.sh            # Debug-Build
scripts/build.sh Release    # Release-Build; weitere Parameter gehen unverändert an xcodebuild
scripts/run.sh              # Debug-Build bauen, laufende TheTap beenden, neuen Build starten
```

`build.sh` erzeugt mit XcodeGen aus `project.yml` das Projekt `TheTap.xcodeproj` und baut es mit `xcodebuild` in den Ordner `build/` (Debug unter `build/Build/Products/Debug/TheTap.app`). Das Xcode-Projekt ist generiert und nicht eingecheckt. Änderungen am Projekt gehören in `project.yml`; das gilt auch für `App/Info.plist`, die XcodeGen erzeugt, die aber eingecheckt ist.

> **Nie zwei Kopien gleichzeitig:** Debug-Build und installierte App haben dieselbe Bundle-ID. Laufen beide, landet `thetap://recheck` womöglich in der falschen. `scripts/run.sh` beendet deshalb jede laufende TheTap. Nach dem Entwickeln startest du die installierte Kopie wieder mit `open /Applications/TheTap.app`.

### Visual Studio Code

Das Projekt ist für VS Code mit der offiziellen [Swift-Erweiterung](https://marketplace.visualstudio.com/items?itemName=swiftlang.swift-vscode) eingerichtet. Über **Terminal → Run Task …** stehen diese Tasks bereit:

| Task        | Befehl                                                        |
| ----------- | ------------------------------------------------------------- |
| Test        | `swift test` in `Packages/BrewCheck`                          |
| CLI         | `swift run brewcheck-cli --no-update` in `Packages/BrewCheck` |
| App bauen   | `scripts/build.sh`                                            |
| App starten | `scripts/run.sh`                                              |

### Tests

```sh
swift test --package-path Packages/BrewCheck
```

Die Kernbibliothek wird mit Swift Testing geprüft, ohne dass dabei echtes brew läuft: Ein `FakeRunner` ersetzt die Befehle, JSON-Beispiele in `Tests/BrewCheckTests/Fixtures/` ersetzen die Ausgabe von brew. Die Tests dürfen nicht von der Umgebung der Maschine abhängen; zur Gegenprobe muss auch dieser Lauf grün sein:

```sh
HOMEBREW_NO_AUTO_UPDATE=1 swift test --package-path Packages/BrewCheck
```

Der Code in `App/` liegt außerhalb des Packages und wird von Hand geprüft.

### Kommandozeile

`brewcheck-cli` prüft wie die App, gibt das Ergebnis aber im Terminal aus. Es dient zum Testen der Kernlogik ohne App:

```sh
cd Packages/BrewCheck
swift run brewcheck-cli [--no-update] [--no-greedy] [--json]
```

| Option        | Wirkung                                         |
| ------------- | ----------------------------------------------- |
| `--no-update` | `brew update` überspringen (schneller Testlauf) |
| `--no-greedy` | Casks mit eigenem Updater nicht einbeziehen     |
| `--json`      | Ausgabe als JSON statt als Tabelle              |

Exit-Code 0 bei erfolgreicher Prüfung, 1 bei einem Fehler, 2 bei unbekannten Optionen.

### Prüfplan testen

Um die automatische Prüfung nicht stundenlang abwarten zu müssen, lässt sich das Intervall per Terminal verkürzen, z. B. auf 3 Minuten (App vorher beenden):

```sh
defaults write io.github.muunleit-projects.thetap checkInterval -float 180
```

Ein Wert außerhalb der Auswahl gilt, wird im Einstellungsfenster aber nicht angezeigt. Danach mit `defaults delete io.github.muunleit-projects.thetap checkInterval` zurücksetzen.

### App-Icon

Das Master-Bild liegt als `design/AppIcon-1024.png` (1024 × 1024 Pixel, mit Transparenz) im Repo. `scripts/make-icons.sh` erzeugt daraus mit `sips` die zehn Größen in `App/Assets.xcassets/AppIcon.appiconset`; `project.yml` verweist über `ASSETCATALOG_COMPILER_APPICON_NAME` darauf. Nach einer Änderung am Master-Bild das Skript erneut ausführen.

### CI und Release

GitHub Actions ([`ci.yml`](.github/workflows/ci.yml)) führt bei jedem Push auf `main` und bei jedem Pull Request auf einem macOS-26-Runner die Tests aus und baut die App.

Ein Tag der Form `vX.Y.Z` startet [`release.yml`](.github/workflows/release.yml): Der Workflow testet das Package, baut die App für Apple Silicon und Intel, packt sie als ZIP und hängt sie an einen GitHub-Release. Tags mit Bindestrich (z. B. `v0.2.0-beta.1`) werden als „Pre-release“ veröffentlicht. Den genauen Ablauf beschreibt [`docs/RELEASE.md`](docs/RELEASE.md).

## Aufbau

Alle Logik, die ohne Oberfläche auskommt, liegt in der Bibliothek BrewCheck; die App ist eine dünne Hülle darum.

```text
TheTap.app (SwiftUI) ─┐
                      ├──► BrewCheck (Bibliothek) ──► brew update / brew outdated
brewcheck-cli ────────┘

TheTap.app ──.command-Skript──► Terminal: brew upgrade ──thetap://recheck──► TheTap.app
```

```text
TheTap/
├── App/                    # Menüleisten-App: Zustand, Prüfplan, Mitteilungen, Upgrade, Logdatei
│   ├── Views/              # Menüleisten-Icon, Panel, Paketliste, Einstellungen
│   └── Assets.xcassets/    # App-Icon (aus design/ erzeugt)
├── Packages/BrewCheck/
│   ├── Sources/BrewCheck/     # brew finden und ausführen, JSON parsen, Regeln, Fehlertexte
│   ├── Sources/BrewCheckCLI/  # brewcheck-cli
│   └── Tests/BrewCheckTests/  # Tests samt JSON-Beispielen
├── design/                 # Master-Bild des App-Icons
├── scripts/                # build.sh, run.sh, install.sh, make-icons.sh
├── docs/                   # Bauplan, Status, Spezifikation, Release-Anleitung
├── project.yml             # XcodeGen-Beschreibung des App-Projekts
└── .github/workflows/      # CI und Release
```

## Gut zu wissen

- **Keine App Sandbox:** Eine App in der Sandbox dürfte `brew` nicht starten. TheTap führt `brew update` und `brew outdated` aus, `brew upgrade` nur auf deinen Klick. Die App selbst sendet nichts ins Netz; Daten lädt nur brew.
- **Ad-hoc-Signatur:** TheTap ist ad hoc signiert und nicht notarisiert (kein Apple-Developer-Konto). Für die selbst gebaute Kopie ist das kein Problem: Mitteilungen und der Start beim Anmelden funktionieren damit. Eine heruntergeladene Kopie musst du beim ersten Start freigeben (siehe [Herunterladen und installieren](#herunterladen-und-installieren)).
- **Gespeicherte Werte:** Einstellungen und die Liste bereits gemeldeter Pakete liegen in den `UserDefaults` unter der Bundle-ID `io.github.muunleit-projects.thetap`.
- **Bekannte Einschränkung:** Das App-Icon erscheint im Finder und in den Anmeldeobjekten. In Mitteilungen und in den Systemeinstellungen unter „Mitteilungen“ zeigt macOS auf dem Entwicklungs-Mac noch ein Platzhalter-Icon; die Ursache ist ungeklärt.
- **Geplant:** der erste veröffentlichte Release (Anleitung in [`docs/RELEASE.md`](docs/RELEASE.md)).

## Weitere Dokumentation

- [`docs/PLAN.md`](docs/PLAN.md): Bauplan mit festen Entscheidungen, Architektur und Phasen
- [`docs/SPEC.md`](docs/SPEC.md): technische Spezifikation und erprobtes Verhalten
- [`docs/STATUS.md`](docs/STATUS.md): aktueller Stand der Entwicklung
- [`docs/RELEASE.md`](docs/RELEASE.md): Ablauf für Releases über GitHub und den Homebrew-Tap

## Lizenz

[MIT](LICENSE) © 2026 muunleit-projects
