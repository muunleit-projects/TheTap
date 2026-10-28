# TheTap – Status

Stand: 27.10.2026

## Aktuelle Phase

Phase 6, Schritt 6 – eine Woche Alltag. Schritte 1 bis 5 sind abgeschlossen. Phase 7a ist vorgezogen und abgenommen. Danach folgen Phase 7b (Update-Test über den eigenen Homebrew-Tap) und Phase 8.

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Zuletzt notierter Commit: `83a151f` (README zu Download und Installation). Die PLAN-Abschnitte aus dem Chat vom 27.10. sind laut ZIP von `main` schon eingepflegt; den Hash mit `git log -1 --oneline` nachtragen.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0. brew liegt unter `/opt/homebrew/bin/brew` (normale Datei, kein Symlink). VS Code mit der Swift-Erweiterung (swiftlang).
- CI: Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3 (älter als der Mac); grün für `83a151f`.
- Release: `release.yml` liegt im Repo und lief einmal grün. Es gibt keinen Release; `v0.1.0-test.1` ist verbraucht.
- Tests: 78 Tests in 7 Suites, lokal (auch mit `HOMEBREW_NO_AUTO_UPDATE=1`) und in der CI grün. Seit Phase 6, Schritt 3 ist das Package unverändert.
- Im Alltag läuft `/Applications/TheTap.app`, installiert mit `scripts/install.sh` (nur `arm64`); „Beim Anmelden starten“ ist an. `checkInterval` ist nicht gesetzt (Standard 6 Stunden) oder steht auf dem zuletzt im Einstellungsfenster gewählten Wert.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen. Der Nutzer lädt sie hoch oder das ganze Repo als ZIP.

## Zuletzt erledigt

- 27.10.2026, Dokumente neu geordnet (**noch nicht committet**):
  - `PLAN.md` gekürzt: abgeschlossene Phasen als Tabelle, Arbeitsregeln gestrafft (neue Regel „Jede Information an einer Stelle“), Projektstruktur aktualisiert (`design/`, `make-icons.sh`, `release.yml`, `SPEC.md`), Phasen 7b und 8 neu gefasst.
  - Neue `docs/SPEC.md` mit der technischen Spezifikation aus `PLAN.md` und den dauerhaften Erkenntnissen aus `STATUS.md` („Erprobtes Verhalten“). Korrigiert: Log-Kategorie `settings` fehlte, Logdatei heißt `thetap.log`.
  - `RELEASE.md` auf den wiederkehrenden Ablauf gekürzt (YAML-Block entfernt), dazu Abschnitt „Homebrew-Tap“ mit Grundgerüst des Casks und dem Schritt „Checksum“ für `release.yml`.
  - `README.md`: `SPEC.md` unter „Aufbau“ und „Weitere Dokumentation“ ergänzt.
  - Homebrew geprüft: Das offizielle Cask-Repo nimmt TheTap nicht auf (Gatekeeper-Pflicht, Mindestzahl an Sternen).
- 27.10.2026, Entscheidungen des Nutzers (in `PLAN.md` eingetragen): eigener Homebrew-Tap, Phase 7b läuft darüber, die Alltagskopie kommt danach nur noch über brew; ein Icon in Mitteilungen ist nicht nötig; die Arbeitsweise bleibt beim Free-Plan (so arbeitet der Nutzer an dem Mac, an dem die App entsteht).

## Offene Probleme

- Warnungen im Release-Build wurden nie ausgewertet. Bei Bedarf: `scripts/build.sh Release ONLY_ACTIVE_ARCH=YES 2>&1 | grep -i warning`.
- Scroll-Grenze der Paketliste (ab 12 Zeilen) nicht bewusst geprüft; am 26. und 27.10. waren 17 bzw. 19 Pakete veraltet. Beim nächsten Öffnen des Panels mit vielen Paketen darauf achten.
- VS Code: Findet die Swift-Erweiterung `Packages/BrewCheck` von selbst (keine roten Fehler in den Quelldateien, Tests in der Seitenleiste)? Außerdem steht `.vscode/` in `.gitignore`, obwohl `tasks.json` und `extensions.json` eingecheckt sind; eine neue Datei dort würde git still ignorieren. Vorschlag: die Zeile durch `.vscode/*`, `!.vscode/tasks.json` und `!.vscode/extensions.json` ersetzen.
- Mitteilungs-Erlaubnis: Warum nach dem ersten Erteilen ein Neustart nötig war, ist ungeklärt; der Wortlaut der Knöpfe im Banner fehlt. Beim ersten Start einer neuen Kopie in Phase 7b beobachten.
- Nicht von Hand getestet: Fehlerpfade von `UpgradeLauncher` (Skript nicht schreibbar, Terminal nicht zu öffnen; bei `cannotOpenScript` steht nur der Pfad im Log), Fehler von `register()`/`unregister()` und der Zustand `.requiresApproval` beim Login-Start, der Rückfall auf `x-apple.systempreferences:`.
- „Log öffnen“ tut nichts, wenn die Datei fehlt; der Rückgabewert von `NSWorkspace.open` wird nicht ausgewertet.
- Ein `checkInterval` außerhalb der Auswahl (z. B. 180 aus Tests) lässt das Auswahlfeld leer; nach Tests mit `defaults delete io.github.muunleit-projects.thetap checkInterval` zurücksetzen.
- Eine geänderte Einstellung „Casks mit eigenem Updater“ wirkt erst ab der nächsten Prüfung; die angezeigte Liste bleibt bis dahin stehen.
- Intel: Die Release-Kopie enthält `x86_64`, wurde aber nie auf einem Intel-Mac gestartet.
- Offene Entscheidungen stehen in `PLAN.md` unter „Offene Punkte“ (Quarantäne im Cask, Updates mit Ad-hoc-Signierung, Standardwerte).

## Nächster Schritt

1. **Neue Dokumente übernehmen:** `docs/PLAN.md`, `docs/STATUS.md`, `docs/RELEASE.md` und `README.md` ersetzen, `docs/SPEC.md` neu anlegen. Dann:

   ```sh
   git add docs/PLAN.md docs/STATUS.md docs/RELEASE.md docs/SPEC.md README.md
   git commit -m "Restructure docs: move spec out of plan, shorten release guide"
   git push
   ```

2. **Phase 6, Schritt 6 – eine Woche Alltag:** Beginn festlegen, Auffälligkeiten hier notieren, danach die Standardwerte prüfen und Phase 6 abnehmen.
3. Danach Phase 7b, Schritt 1: Homebrew-Tap anlegen und den Schritt „Checksum“ in `release.yml` ergänzen (`RELEASE.md`, „Homebrew-Tap“).

Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`. Für Phase 7b zusätzlich `RELEASE.md` (und `.github/workflows/release.yml`, falls der Schritt „Checksum“ noch fehlt).
