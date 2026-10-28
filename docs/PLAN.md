# TheTap – Bauplan für die KI

20.10.2026, neu gegliedert am 27.10.2026 · @M.

## Zweck und Kontext

TheTap ist eine Menüleisten-App für macOS, die regelmäßig prüft, welche Homebrew-Pakete veraltet sind, darüber per Mitteilung informiert und auf Klick alle Upgrades im Terminal startet. Sie ist in erster Linie für den Eigengebrauch gedacht; andere laden die fertig gebaute App von GitHub herunter (Phase 7a), später auch über einen eigenen Homebrew-Tap (Phase 8).

Vorbild ist [muunleit-projects/show_updates](https://github.com/muunleit-projects/show_updates): eine Go-App mit Fyne-Fenster, die beim Login `brew update` und `brew outdated` ausführt. TheTap baut die Idee in Swift neu und ersetzt das Fenster durch ein Icon in der Menüleiste, das selbstständig prüft.

Dieses Dokument ist die Arbeitsanweisung für die KI, die die App baut. Lies es zu Beginn jeder Sitzung ganz. Die Entscheidungen im Abschnitt „Feste Entscheidungen“ gelten; willst du davon abweichen, frag zuerst den Nutzer. Widerspricht eine hochgeladene Datei dem Plan, gilt die Datei; sprich den Widerspruch an und passe den Plan an.

| Datei            | Inhalt                                                      | Hochladen                                          |
| ---------------- | ----------------------------------------------------------- | -------------------------------------------------- |
| `docs/PLAN.md`   | Arbeitsregeln, feste Entscheidungen, Phasen, offene Punkte  | in jedem Chat                                      |
| `docs/STATUS.md` | aktueller Stand, offene Probleme, nächster Schritt          | in jedem Chat                                      |
| `docs/SPEC.md`   | technische Spezifikation und erprobtes Verhalten            | wenn Code, ein Skript oder `project.yml` sich ändert |
| `docs/RELEASE.md`| Ablauf eines Releases, Homebrew-Tap                         | wenn ein Release oder der Tap dran ist             |
| `README.md`      | Anleitung für Nutzer der App                                | wenn sich sichtbares Verhalten ändert              |

## Arbeitsregeln für die KI

Der Nutzer hat keine Erfahrung mit Swift und Xcode, aber etwas mit Visual Studio Code, und verlässt sich auf dich. Arbeite deshalb in kleinen, überprüfbaren Schritten und erkläre alles, was er selbst tun muss.

- **Arbeitsweise: Chat.** Du arbeitest im Chat (Claude, Free-Plan; so arbeitet der Nutzer an dem Mac, an dem die App entsteht) und hast keinen Zugriff auf den Mac. Der Nutzer führt jeden Befehl selbst aus und kopiert dir das Ergebnis in den Chat. Maßgeblich sind die Dateien, die in diesem Chat vorliegen; frag nach einer Datei, statt ihren Inhalt zu raten.
- **Sitzungsstart.** Jeder neue Chat beginnt im selben Projekt. Der Nutzer lädt `PLAN.md`, `STATUS.md` und die Dateien hoch, die `STATUS.md` unter „Nächster Schritt“ nennt. Alternativ lädt er das ganze Repo als ZIP hoch (auf GitHub „Code“ → „Download ZIP“; enthält den Stand des letzten Pushs).
- **Sitzungsende.** Am Ende jedes Chats, wenn ein Schritt erledigt ist oder der Nutzer es verlangt, lieferst du eine aktualisierte `STATUS.md`: aktuelle Phase und Schritt, letzter Commit, zuletzt erledigte Schritte, offene Probleme, nächster Schritt und die Dateien für den nächsten Chat.
- **Jede Information an einer Stelle.** Neue Entscheidungen kommen nach `PLAN.md` unter „Feste Entscheidungen“, dauerhafte Erkenntnisse (Verhalten von macOS, brew, Swift, Toolchain) nach `SPEC.md` unter „Erprobtes Verhalten“, alles Vorläufige nach `STATUS.md`. Nichts wird zusätzlich an einer zweiten Stelle festgehalten. Der Fortschritt innerhalb einer Phase steht nur in `STATUS.md`; ist eine Phase abgenommen, trägst du sie in `PLAN.md` unter „Abgeschlossene Phasen“ ein und kürzt `STATUS.md`. Einzelheiten zu erledigten Schritten stehen in den Commits.
- **Ein Schritt pro Antwort.** Jede Antwort enthält einen überschaubaren Schritt: welche Dateien, ihr Inhalt, die Befehle zum Prüfen mit der erwarteten Ausgabe und was der Nutzer zurückmelden soll. Danach wartest du auf die Rückmeldung.
- **Immer ganze Dateien.** Gib jede neue oder geänderte Datei vollständig aus, mit ihrem Pfad als Überschrift, nie als Ausschnitt oder Diff. Der Nutzer ersetzt den Dateiinhalt komplett. Halte Dateien klein, lieber mehrere kurze als eine lange. Ausnahmen sind `PLAN.md`, `SPEC.md` und `README.md`: Dort gibst du nur die geänderten Abschnitte aus, jeden vollständig von seiner Überschrift bis zur nächsten, und sagst, welchen Abschnitt er ersetzt. Kannst du Dateien zum Herunterladen liefern, lieferst du auch diese drei vollständig.
- **Erst grün, dann weiter.** Nach jeder Code-Änderung lässt du den Nutzer `swift build` und `swift test` im Package und `scripts/build.sh` ausführen. Bei Fehlern zuerst reparieren. Reine Änderungen an Dokumenten brauchen das nicht.
- **Sparsam mit Ausgaben und Kontingent.** Der Free-Plan hat ein Nutzungslimit, das sich alle fünf Stunden erneuert. Keine langen Erklärungen ohne Anlass und keinen Code doppelt ausgeben. Bei langen Ausgaben bittest du nur um die Fehlermeldungen oder die letzten Zeilen und nennst den passenden Befehl, z. B. `swift test 2>&1 | tail -40`.
- **Editor ist VS Code.** Der Nutzer arbeitet in Visual Studio Code mit der offiziellen Swift-Erweiterung, nicht in der Xcode-Oberfläche. Alles muss sich per Terminal-Befehl oder VS-Code-Task bauen, testen und starten lassen. Setzt ein Schritt doch Xcode voraus, kennzeichne ihn ausdrücklich als Ausnahme.
- **Klickanleitungen für den Nutzer.** Alles, was er in VS Code, im Finder, auf GitHub oder in den Systemeinstellungen tun muss, beschreibst du als nummerierte Schrittfolge mit den genauen Menü- und Knopfnamen.
- **Fachbegriffe erklären.** Beim ersten Auftreten eines Swift- oder Homebrew-Begriffs ein Satz Erklärung.
- **Nichts erfinden.** Bei Unsicherheit über eine Apple-API, ein SF-Symbol, ein brew-Flag oder eine Cask-Angabe sagst du das offen und lässt den Nutzer nachprüfen (z. B. mit `brew <befehl> --help` oder `brew audit`), statt zu raten.
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
- **Signierung:** Ad hoc (`CODE_SIGN_IDENTITY: "-"` in `project.yml`), lokal und in GitHub Actions. **Kein Apple Developer Program** (entschieden am 20.10.2026), also keine Developer-ID-Signatur und keine Notarisierung. Geprüft: Mitteilungen und Login-Start funktionieren damit, auch nach einem Neubau (22. und 26.10.2026); ein kostenloses „Personal Team“ ist nicht nötig. _Grund:_ Kostenlos; Mitteilungs-Erlaubnis und Login-Start hängen an der Bundle-ID. Folge: Wer die App herunterlädt, muss sie beim ersten Start in den Systemeinstellungen freigeben.
- **Verteilung:** GitHub Releases: Ein Versions-Tag `vX.Y.Z` startet `.github/workflows/release.yml`; der Workflow baut eine Release-App für Apple Silicon und Intel und hängt sie als ZIP an den Release. _Grund:_ Kostenlos, ohne eigenen Server; gebaut wird auf einem sauberen GitHub-Runner, nicht auf dem Mac des Nutzers.
- **Homebrew:** eigener Tap `muunleit-projects/homebrew-tap` mit dem Cask `thetap` (entschieden am 27.10.2026). Ab Phase 7b kommt die Alltagskopie in `/Applications` nur noch über brew; `scripts/install.sh` würde die von brew verwaltete Kopie überschreiben, ohne dass brew es merkt. Zum Entwickeln bleibt `scripts/run.sh`. _Grund:_ Das offizielle `homebrew/cask` nimmt keine nicht notarisierten Apps auf (siehe Phase 8); ein eigener Tap ist kostenlos, und Updates laufen über TheTap selbst („Alles aktualisieren“).
- **Versionsnummer:** Der Tag gibt die Version vor (`v0.2.0` → `0.2.0`); `MARKETING_VERSION` in `project.yml` wird vor dem Taggen auf dieselbe Nummer gesetzt. _Grund:_ `Info.plist` liest Version und Build-Nummer aus den Build-Einstellungen.
- **Repo:** [muunleit-projects/TheTap](https://github.com/muunleit-projects/TheTap), Branch `main`, auf den Mac geklont nach `~/Programmieren/swift/TheTap`.
- **CI:** GitHub Actions auf dem Runner `macos-26`: `swift test` und App-Build bei jedem Push auf `main` und bei Pull Requests, ohne `if:`-Bedingungen. _Grund:_ Zweite, unabhängige Prüfung neben den Testläufen des Nutzers.

## Architektur und Projektstruktur

Alle Logik, die ohne Oberfläche auskommt, liegt in der Bibliothek BrewCheck; die App ist nur eine dünne Hülle darum. So lässt sich der Kern mit `swift test` und der CLI prüfen, ohne Xcode zu öffnen. Die genaue Spezifikation steht in `SPEC.md`.

```text
TheTap.app (SwiftUI) ─┐
                      ├──► BrewCheck (Bibliothek) ──Process──► brew update / outdated
brewcheck-cli ────────┘

TheTap.app ──.command-Skript──► Terminal: brew upgrade ──thetap://recheck──► TheTap.app
```

- **BrewCheck** (Swift Package, Bibliothek): brew finden, Befehle mit Timeout ausführen, JSON parsen, den Text des Upgrade-Skripts erzeugen, deutsche Fehlertexte, dazu reine Entscheidungsregeln (`Policies`).
- **brewcheck-cli** (Swift Package, ausführbar): ruft BrewCheck auf und gibt die Liste im Terminal aus. Nur zum Testen.
- **TheTap** (App-Target): Menüleiste, Zustand, Netzwerkstatus, Zeitplan, Mitteilungen, Upgrade-Start, Einstellungen, Logdatei.

```text
TheTap/                          # Repo-Wurzel
├── project.yml                  # XcodeGen-Beschreibung des App-Projekts
├── README.md                    # Anleitung für Nutzer
├── LICENSE                      # MIT
├── Packages/BrewCheck/
│   ├── Package.swift
│   ├── Sources/
│   │   ├── BrewCheck/           # Bibliothek
│   │   └── BrewCheckCLI/        # ausführbares Produkt "brewcheck-cli"
│   └── Tests/BrewCheckTests/
│       └── Fixtures/            # JSON-Beispiele, real.json aus echtem brew
├── App/
│   ├── TheTapApp.swift          # @main, MenuBarExtra, Settings-Szene
│   ├── AppDelegate.swift        # hält AppState und Scheduler, URL-Schema, Mitteilungs-Delegate
│   ├── AppState.swift           # @Observable, @MainActor
│   ├── NetworkMonitor.swift     # NWPathMonitor
│   ├── Scheduler.swift          # Start, Wecker, Aufwachen
│   ├── Notifier.swift           # Mitteilungen
│   ├── UpgradeLauncher.swift    # .command-Skript ins Terminal
│   ├── LogFile.swift            # ~/Library/Logs/TheTap/thetap.log
│   ├── Views/                   # MenuBarLabel, PanelView, PackageListView, SettingsView
│   ├── Info.plist               # von XcodeGen erzeugt, eingecheckt
│   └── Assets.xcassets/         # App-Icon, erzeugt aus design/
├── design/AppIcon-1024.png      # Master des App-Icons
├── scripts/
│   ├── build.sh                 # xcodegen generate + xcodebuild (Debug, oder Release als 1. Parameter)
│   ├── run.sh                   # Debug bauen, laufende App beenden, neu starten
│   ├── install.sh               # Release-Build nach /Applications
│   └── make-icons.sh            # Icon-Größen aus design/ erzeugen
├── .vscode/                     # tasks.json (Test, CLI, App bauen, App starten), extensions.json
├── .github/workflows/
│   ├── ci.yml                   # swift test + App-Build bei Push und Pull Request
│   └── release.yml              # bei Tag v…: Release-Build, ZIP, GitHub-Release
├── docs/                        # PLAN.md, STATUS.md, SPEC.md, RELEASE.md
└── .gitignore                   # u. a. TheTap.xcodeproj/, build/, .build/
```

**Achtung Ordnernamen:** Der CLI-Ordner heißt `BrewCheckCLI`, nicht `brewcheck`. Das macOS-Dateisystem unterscheidet standardmäßig nicht zwischen Groß- und Kleinschreibung; `BrewCheck` und `brewcheck` wären derselbe Ordner.

**XcodeGen statt Xcode-Oberfläche:** Eine Mac-App braucht ein Xcode-Projekt, aber niemand muss es in Xcode öffnen. Mit [XcodeGen](https://github.com/yonaskolb/XcodeGen) beschreibt `project.yml` das Projekt als lesbaren Text; `xcodegen generate` erzeugt daraus `TheTap.xcodeproj`, und `xcodebuild` baut die App. Du änderst nur `project.yml`. Was darin steht und was die Skripte tun, beschreibt `SPEC.md` unter „Projekt und Build“.

## Phasenplan

Jede Phase endet mit einem lauffähigen Stand und Kriterien, die der Nutzer selbst abhakt. Eine Phase beginnt erst, wenn die vorige abgehakt ist; Ausnahmen sind vermerkt. Größere Phasen sind in nummerierte Schritte geteilt. Jeder Schritt, der Code ändert, endet mit grünem `swift test`, grünem `scripts/build.sh` und einem Commit; `STATUS.md` nennt den aktuellen Schritt.

### Abgeschlossene Phasen

| Phase                                   | Inhalt                                                                                         | Abgenommen | Letzter Commit |
| --------------------------------------- | ---------------------------------------------------------------------------------------------- | ---------- | -------------- |
| 0 – Werkzeuge und Repo                  | Xcode, Swift-Erweiterung, XcodeGen, Repo, `.gitignore`, `docs/`, `.vscode/`, CI                | ✓          | –              |
| 1 – Kernbibliothek mit Tests            | Datenmodell, `BrewLocator`, `ProcessRunner`, `OutdatedParser`, `BrewChecker`, `Policies`       | ✓          | –              |
| 2 – CLI                                 | `BrewCheckError.userMessage`, `brewcheck-cli`                                                   | ✓          | –              |
| 3 – App-Gerüst                          | `project.yml`, `build.sh`, `run.sh`, `MenuBarExtra`, `AppState`, Panel                          | ✓          | –              |
| 4 – Upgrade und Recheck                 | `UpgradeScript`, `UpgradeLauncher`, `thetap://recheck`, Zustand „Upgrade läuft“                 | ✓          | `64eaa17`      |
| 5 – Automatik und Mitteilungen          | `NetworkMonitor`, `checkIfDue()`, Scheduler, stille Wiederholung, `Notifier` mit Aktion         | 22.10.2026 | `a8c0114`      |
| 7a – Build und Release über GitHub      | Version aus Build-Einstellungen, `release.yml`, Testrelease (gelöscht), README zum Download      | 27.10.2026 | `83a151f`      |

Phase 7a wurde vor Phase 6, Schritt 6 gezogen, weil sie den App-Code nicht berührt. Die ausführlichen Schritte und Abnahmekriterien dieser Phasen stehen in der Git-Historie dieser Datei (Fassung vor dem 27.10.2026).

### Phase 6 – Einstellungen, Login-Start, Feinschliff

Schritte 1 bis 5 sind abgeschlossen: Logdatei (`5ebc449`, `c70a664`, `62c7d35`), Einstellungsfenster (`ff90382`), Installation mit `scripts/install.sh` (`5c5661c`), „Beim Anmelden starten“ (`7de6bf9`), App-Icon (`ecfb5c1`). Die Spezifikation steht in `SPEC.md`.

6. **Eine Woche Alltag** – nichts zu bauen. Der Nutzer benutzt die Kopie in `/Applications`, notiert Auffälligkeiten in `STATUS.md` und prüft danach die Standardwerte (Prüfintervall 6 Stunden, `--greedy` an). Beginn und Ende legt der Nutzer fest.

Abnahme:

- [x] Die Einstellungen öffnen sich im Vordergrund; alle Werte bleiben nach einem Neustart der App erhalten
- [x] Ein geändertes Prüfintervall wirkt ohne Neustart der App
- [x] „Beim Anmelden starten“ funktioniert nach Ab- und Anmelden
- [x] Bei einem Fehler entsteht die Logdatei unter `~/Library/Logs/TheTap/`; „Log öffnen“ zeigt sie
- [x] Die App hat ein eigenes Icon im Finder und in den Anmeldeobjekten (geprüft am 27.10.2026). Ein eigenes Icon in Mitteilungen braucht der Nutzer nicht (entschieden am 27.10.2026); dort zeigt macOS weiter einen Platzhalter.
- [ ] Die App liegt in `/Applications` und läuft eine Woche ohne Auffälligkeiten; die Standardwerte sind bestätigt oder angepasst

### Phase 7b – Update-Test über einen eigenen Homebrew-Tap

Klärt, was beim Ersetzen einer installierten Version durch eine neuere passiert. Jeder Ad-hoc-Build hat eine andere Signatur; ob macOS Freigabe, Mitteilungs-Erlaubnis und Login-Start behält, zeigt nur ein echtes Update.

Der Test läuft gleich über den eigenen Homebrew-Tap (entschieden am 27.10.2026, siehe „Feste Entscheidungen“). Homebrew markiert Downloads genauso als „aus dem Internet geladen“ wie der Browser, die Antwort gilt also auch für den Download der ZIP. Zusätzlich zeigt sich, ob TheTap sich über „Alles aktualisieren“ selbst aktualisieren kann.

1. **Tap anlegen:** Repo `muunleit-projects/homebrew-tap` mit `Casks/thetap.rb`; in `release.yml` den Schritt „Checksum“ ergänzen. Anleitung und Grundgerüst in `RELEASE.md` unter „Homebrew-Tap“.
2. **Erste Version:** `MARKETING_VERSION` auf `1.0.0` setzen, `v1.0.0-beta.1` veröffentlichen und den Cask darauf setzen (`RELEASE.md`). TheTap über „Beenden“ schließen und `/Applications/TheTap.app` in den Papierkorb legen, sonst bricht brew ab, weil dort schon eine App liegt. Dann `brew install --cask muunleit-projects/tap/thetap`, freigeben, Mitteilungen erlauben, „Beim Anmelden starten“ einschalten und einige Tage so benutzen. Ab hier kommt die Alltagskopie nur noch über brew, nicht mehr über `scripts/install.sh`.
3. **Zweite Version:** `v1.0.0` veröffentlichen, den Cask aktualisieren und pushen. In TheTap „Jetzt prüfen“: `thetap` steht in der Liste. „Alles aktualisieren“ klicken. Erwartet: brew beendet TheTap, installiert die neue Version, und `thetap://recheck` am Ende des Skripts startet sie.
4. **Beobachten und festhalten** (README unter „Aktualisieren“, dauerhafte Erkenntnisse in `SPEC.md`): Verlangt macOS die Freigabe in „Datenschutz & Sicherheit“ erneut? Bleiben Mitteilungs-Erlaubnis und „Beim Anmelden starten“ erhalten? Fragt macOS, ob Terminal TheTap steuern darf (das Beenden vor dem Upgrade läuft über ein Apple-Event)? Meldet TheTap nach der Installation über den Tap Fehler bei der Prüfung (Stichwort Tap-Vertrauen, siehe Phase 8)?

Abnahme:

- [ ] Die Installation über den Tap klappt; TheTap prüft danach ohne Fehler
- [ ] Die neuere Version erscheint in der Paketliste und lässt sich über „Alles aktualisieren“ installieren; danach läuft genau eine TheTap, und `brew list --cask --versions thetap` zeigt die neue Version
- [ ] Die README sagt, ob Freigabe, Mitteilungs-Erlaubnis und „Beim Anmelden starten“ nach einem Update erhalten bleiben oder neu eingeschaltet werden müssen

### Phase 8 – Homebrew-Tap veröffentlichen

Geklärt am 27.10.2026 anhand der Homebrew-Dokumentation: Ins offizielle Repository `homebrew/cask` kommt TheTap nicht. Apps in offiziellen Casks müssen die Gatekeeper-Prüfung auf einem Mac mit Standardeinstellungen bestehen, was Developer-ID-Signatur und Notarisierung voraussetzt; Casks ohne beides hat Homebrew mit Version 5.0.0 abgekündigt und bis September 2026 entfernt. Außerdem braucht ein vom Autor selbst eingereichtes Paket mindestens 225 Sterne, 90 Forks oder 90 Beobachter. Der Weg ist ein eigener Tap: ein öffentliches Repo `muunleit-projects/homebrew-tap` mit `Casks/thetap.rb`. Ablauf und Grundgerüst stehen in `RELEASE.md` unter „Homebrew-Tap“.

Was für Nutzer des Taps gilt:

- **Tap-Vertrauen (seit Homebrew 6.0.0):** Pakete aus fremden Taps lädt brew nur nach ausdrücklichem Vertrauen. Wer mit vollem Namen installiert (`brew install --cask muunleit-projects/tap/thetap`), vertraut damit genau diesem Cask; einen eigenen `brew trust`-Schritt braucht es dann nicht.
- **Keine Abkürzung an Gatekeeper vorbei:** `--no-quarantine` gibt es nicht mehr. Die Freigabe in „Datenschutz & Sicherheit“ ist also auch bei Homebrew nötig, genau wie beim Download.

Schritte (nach Phase 7b):

1. README: Abschnitt „Mit Homebrew installieren“ mit Befehl, Freigabe (Verweis auf den vorhandenen Abschnitt), Update über „Alles aktualisieren“ oder `brew upgrade --cask thetap` und Deinstallation mit `brew uninstall --cask thetap` (mit `--zap` samt Einstellungen und Log).
2. Optional: den Cask bei jedem Release automatisch aktualisieren. Das braucht einen Token mit Schreibrecht auf das Tap-Repo als Secret im TheTap-Repo; bis dahin von Hand nach `RELEASE.md`.

Abnahme:

- [ ] `brew audit --cask --strict muunleit-projects/tap/thetap` meldet keine Fehler
- [ ] Die README beschreibt Installation, Freigabe, Update und Deinstallation über Homebrew
- [ ] Ein Release lässt sich mit den Schritten aus `RELEASE.md` bis in den Tap bringen

## Offene Punkte

Diese Punkte sind noch nicht entschieden oder geklärt. Trage die Antwort unter „Feste Entscheidungen“ (oder in `SPEC.md` unter „Erprobtes Verhalten“) ein und lösche den Punkt.

- [ ] **Quarantäne im Cask:** Ein `postflight`-Block im Cask könnte nach der Installation `xattr -dr com.apple.quarantine` ausführen. Dann entfiele die Freigabe, aber auch die Prüfung durch Gatekeeper, ohne dass der Nutzer davon etwas merkt. Vorschlag: zuerst ohne, Entscheidung nach Phase 7b. Ob Homebrew das in fremden Taps weiter zulässt, ist nicht geprüft.
- [ ] **Updates mit Ad-hoc-Signierung:** Bleiben Freigabe, Mitteilungs-Erlaubnis und Login-Start nach einem Update erhalten? Beim Ersetzen der lokalen Kopie durch den Download (27.10.2026) blieben Mitteilungs-Erlaubnis und Anmeldeobjekt erhalten; offen ist, ob eine neuere Version die Freigabe erneut verlangt. Klärt Phase 7b.
- [ ] **Standardwerte:** Prüfintervall 6 Stunden und `--greedy` an sind Vorschläge; der Nutzer entscheidet nach der Woche Alltag (Phase 6, Schritt 6).

## Quellen

- [muunleit-projects/show_updates](https://github.com/muunleit-projects/show_updates) – Vorbild, insbesondere [checkupdates.go](https://raw.githubusercontent.com/muunleit-projects/show_updates/main/pkg/checkupdates/checkupdates.go)
- [Homebrew-Manpage](https://docs.brew.sh/Manpage) – Optionen von `outdated` und `upgrade` (`--json=v2`, `--greedy`, `--no-ask`), `brew trust`, Umgebungsvariablen
- [XcodeGen](https://github.com/yonaskolb/XcodeGen), Standardwerte der Info.plist in [InfoPlistGenerator.swift](https://github.com/yonaskolb/XcodeGen/blob/master/Sources/XcodeGenKit/InfoPlistGenerator.swift)
- [gh release create](https://cli.github.com/manual/gh_release_create) – Optionen `--verify-tag`, `--prerelease`, `--generate-notes`
- [Apple: Safely open apps on your Mac](https://support.apple.com/en-us/102445) – Freigabe nicht notarisierter Apps über „Datenschutz & Sicherheit“
- Homebrew: [Acceptable Casks](https://docs.brew.sh/Acceptable-Casks) (Gatekeeper-Pflicht), [Package Acceptance Policy](https://docs.brew.sh/Package-Acceptance-Policy) (Sterne, Forks, Beobachter), [Tap Trust](https://docs.brew.sh/Tap-Trust), [How to Create and Maintain a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap), [Cask Cookbook](https://docs.brew.sh/Cask-Cookbook), [Security and Supply Chain](https://docs.brew.sh/Homebrew-Security-and-Supply-Chain) (Quarantäne)
- [Workbrew: What Homebrew 5.0.0 means](https://workbrew.com/blog/what-homebrew-5-0-0-means-for-your-mac-fleet) – Ende von `--no-quarantine`, Entfernen nicht notarisierter Casks bis September 2026
