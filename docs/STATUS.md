# TheTap – Status

Stand: 24.11.2026

## Aktuelle Phase

Phase 7b, Schritt 2 erledigt (Installation über den Tap, `1.0.0-beta.1`); die Beta wird jetzt einige Tage im Alltag benutzt. Danach Schritt 3 (zweite Version). Phase 6 und Phase 7a sind abgenommen. Danach folgt Phase 8.

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Letzter Code-Commit: `700adfc` („Bump version to 1.0.0“), CI grün. Tag `v1.0.0-beta.1` zeigt auf `700adfc`; der Release-Lauf war grün, einschließlich des Schritts „Checksum“.
- Release: „TheTap 1.0.0-beta.1“ (Pre-release) mit `TheTap-1.0.0-beta.1.zip`; SHA-256 `1f4e154791e8d0840217bbf7516d6dce9f8936ad9d6f9a343cb2a32f628a4dd1`. `v0.1.0-test.1` ist verbraucht.
- Tap-Repo: https://github.com/muunleit-projects/homebrew-tap (öffentlich), lokal unter `~/Programmieren/homebrew-tap`. `Casks/thetap.rb` mit Version `1.0.0-beta.1` (Commit `98c8205`). `brew audit --cask --strict` ergibt Exit-Code 0. Der Cask ist per `brew trust --cask muunleit-projects/tap/thetap` als vertrauenswürdig eingetragen.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0. brew liegt unter `/opt/homebrew/bin/brew`. VS Code mit der Swift-Erweiterung.
- CI: Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3.
- Tests: 81 Tests in 7 Suites, lokal und in der CI grün.
- Alltagskopie: `/Applications/TheTap.app`, installiert über brew (`thetap 1.0.0-beta.1`); „Beim Anmelden starten“ ist an. `scripts/install.sh` wird nicht mehr benutzt; zum Entwickeln gilt `scripts/run.sh`.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen. Der Nutzer lädt sie hoch oder das ganze Repo als ZIP.

## Zuletzt erledigt

- 24.11.2026, Phase 7b, Schritt 2: `MARKETING_VERSION` auf `1.0.0` (`700adfc`), `v1.0.0-beta.1` veröffentlicht, Cask angelegt, Audit sauber, TheTap über `brew install --cask muunleit-projects/tap/thetap` installiert. Beobachtet: Freigabe-Dialoge wie in der README; keine neue Abfrage der Mitteilungs-Erlaubnis; „Beim Anmelden starten“ blieb an; Menüleiste und „Jetzt prüfen“ ohne Fehler.
- 24.11.2026, Phase 7b, Schritt 1: Name `thetap` frei, Schritt „Checksum“ in `release.yml` (`f9d9705`), Tap-Repo angelegt.
- 24.11.2026, Phase 6 abgenommen (`1297ba4`).

## Offene Probleme

- `brew audit` und `brew load` verweigern Casks aus fremden Taps ohne `brew trust`. Ob `brew install` mit vollem Namen allein genügt (so steht es in `PLAN.md`, Phase 8), ist offen, weil der Trust schon vor der Installation gesetzt wurde. Für die README in Phase 8 klären.
- Offen für Schritt 3: Erkennt `brew outdated --cask --greedy` den Wechsel von `1.0.0-beta.1` auf `1.0.0` als Update? Die App-Version ist in beiden `1.0.0`, nur die Build-Nummer unterscheidet sich.
- Das Icon in Mitteilungen und unter Systemeinstellungen → Mitteilungen ist weiterhin das alte Platzhalter-Icon (auch nach dem Wechsel auf die brew-Kopie, 24.11.2026).
- Warnungen im Release-Build wurden nie ausgewertet. Bei Bedarf: `scripts/build.sh Release ONLY_ACTIVE_ARCH=YES 2>&1 | grep -i warning`.
- Scroll-Grenze der Paketliste (ab 12 Zeilen) nicht bewusst geprüft. Beim nächsten Öffnen des Panels mit vielen Paketen darauf achten.
- VS Code: Findet die Swift-Erweiterung `Packages/BrewCheck` von selbst (keine roten Fehler, Tests in der Seitenleiste)?
- Nicht von Hand getestet: Fehlerpfade von `UpgradeLauncher`, Fehler von `register()`/`unregister()`, der Zustand `.requiresApproval` beim Login-Start, der Rückfall auf `x-apple.systempreferences:`.
- „Log öffnen“ tut nichts, wenn die Datei fehlt.
- Ein `checkInterval` außerhalb der Auswahl lässt das Auswahlfeld leer; nach Tests mit `defaults delete io.github.muunleit-projects.thetap checkInterval` zurücksetzen.
- Eine geänderte Einstellung „Casks mit eigenem Updater“ wirkt erst ab der nächsten Prüfung.
- Intel: Die Release-Kopie enthält `x86_64`, wurde aber nie auf einem Intel-Mac gestartet.
- Offene Entscheidungen stehen in `PLAN.md` unter „Offene Punkte“.

## Nächster Schritt

1. Einige Tage die Beta über brew benutzen; Auffälligkeiten notieren.
2. **Phase 7b, Schritt 3:** `v1.0.0` taggen (`MARKETING_VERSION` steht schon auf `1.0.0`, kein Bump nötig), SHA-256 aus „Checksum“ notieren, Cask im Tap auf `1.0.0` und neue Prüfsumme setzen, Audit, pushen. In TheTap „Jetzt prüfen“: steht `thetap` in der Liste? Dann „Alles aktualisieren“. Danach Schritt 4 (Beobachtungen in README und `SPEC.md`).

Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`, `RELEASE.md` und `project.yml`.
