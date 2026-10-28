# TheTap – Status

Stand: 28.10.2026

## Aktuelle Phase

Phase 6, Schritt 6 – eine Woche Alltag, **Beginn 28.10.2026, Ende Sonntag 08.11.2026**. Schritte 1 bis 5 sind abgeschlossen. Phase 7a ist vorgezogen und abgenommen. Danach folgen Phase 7b (Update-Test über den eigenen Homebrew-Tap) und Phase 8. Ob nach der Woche eine zweite Testwoche folgt, entscheidet der Nutzer anhand der Liste unter „Auffälligkeiten in der Woche Alltag“.

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Letzter Commit vor dieser Aktualisierung: `eb0b7ae` („Ignore only .vscode/settings.json“); die CI war zuletzt für `2ad2769` als grün gemeldet.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0. brew liegt unter `/opt/homebrew/bin/brew` (normale Datei, kein Symlink). VS Code mit der Swift-Erweiterung (swiftlang).
- CI: Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3 (älter als der Mac).
- Release: `release.yml` liegt im Repo und lief einmal grün. Es gibt keinen Release; `v0.1.0-test.1` ist verbraucht.
- Tests: 78 Tests in 7 Suites, lokal (auch mit `HOMEBREW_NO_AUTO_UPDATE=1`) und in der CI grün. Seit Phase 6, Schritt 3 ist das Package unverändert.
- Im Alltag läuft `/Applications/TheTap.app`, installiert mit `scripts/install.sh` (nur `arm64`); „Beim Anmelden starten“ ist an. `checkInterval` ist nicht gesetzt (Standard 6 Stunden) oder steht auf dem zuletzt im Einstellungsfenster gewählten Wert.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen. Der Nutzer lädt sie hoch oder das ganze Repo als ZIP.

## Zuletzt erledigt

- 28.10.2026, `.gitignore` angepasst (`eb0b7ae`): unter „Visual Studio Code“ steht nur noch `.vscode/settings.json` (die lokale Rechtschreibprüfung des Nutzers, für das Projekt unwichtig). `tasks.json` und `extensions.json` bleiben damit versionierbar.
- 28.10.2026, Dokumente neu geordnet und veröffentlicht (`2842f3e`, `d428642`, `2ad2769`): `PLAN.md` gekürzt, neue `docs/SPEC.md`, `RELEASE.md` auf den wiederkehrenden Ablauf gekürzt (mit Abschnitt „Homebrew-Tap“), `README.md` im Repo-Wurzelordner um `SPEC.md` ergänzt. Dabei war die README zunächst versehentlich nach `docs/` geraten und alle Dokumente ausführbar (Modus 755); beides ist korrigiert.
- 27.10.2026, Entscheidungen des Nutzers (in `PLAN.md` eingetragen): eigener Homebrew-Tap, Phase 7b läuft darüber, die Alltagskopie kommt danach nur noch über brew; ein Icon in Mitteilungen ist nicht nötig; die Arbeitsweise bleibt beim Free-Plan.
- 27.10.2026, Homebrew geprüft: Das offizielle Cask-Repo nimmt TheTap nicht auf (Gatekeeper-Pflicht, Mindestzahl an Sternen).

## Auffälligkeiten in der Woche Alltag

Der Nutzer trägt hier ein, was ihm auffällt (Datum, was passiert ist, wie es sich zeigt). Nach dem 08.11.2026 wird die Liste durchgegangen: Was wird gebaut, was bleibt, folgt eine zweite Testwoche?

- **Abbruch des Upgrades (28.10.2026, durch Überlegung gefunden, nicht beobachtet):** Bricht der Nutzer `brew upgrade` im Terminal ab (Strg+C) oder schließt das Fenster, kommt vermutlich kein `thetap://recheck` an, weil das Skript den Aufruf erst nach `brew upgrade` ausführt (siehe `SPEC.md`, „Upgrade (`UpgradeLauncher`)“). Der Zustand „Upgrade läuft“ bleibt dann bis zu 2 Stunden stehen: Prüfungen und die Knöpfe „Alles aktualisieren“ und „Jetzt prüfen“ sind gesperrt, es kommen keine Mitteilungen, das Panel zeigt „Upgrade läuft im Terminal …“, und die Liste kann schon aktualisierte Pakete enthalten. Ob das Skript bei Strg+C sofort endet und ob ein `EXIT`-Trap in zsh auch beim Schließen des Fensters läuft, ist nicht erprobt.
  - **Vorläufige Richtung (Nutzer, 28.10.2026):** Variante 1, also der Recheck über `trap '…' EXIT` im Upgrade-Skript (in `UpgradeScript.content`, getestet in `UpgradeScriptTests`) statt über einen festen `open`-Aufruf am Ende, damit er nicht doppelt kommt. Variante 2 (das Skript schreibt seine PID in eine Datei, die App prüft in „Upgrade läuft“, ob der Prozess noch lebt) nur, falls sich zeigt, dass das Schließen des Fensters nicht abgedeckt ist.
  - **Zeitpunkt:** Umgesetzt wird erst nach der Testwoche. Vorher darf `/Applications/TheTap.app` nicht ersetzt werden.
  - **Handprobe (ändert nichts am Code, Zeitpunkt offen):** Bei einem veralteten Paket „Alles aktualisieren“ klicken, im Terminal Strg+C drücken und beobachten, ob „Upgrade läuft im Terminal …“ stehen bleibt; danach dasselbe durch Schließen des Fensters.

## Offene Probleme

- Warnungen im Release-Build wurden nie ausgewertet. Bei Bedarf: `scripts/build.sh Release ONLY_ACTIVE_ARCH=YES 2>&1 | grep -i warning`.
- Scroll-Grenze der Paketliste (ab 12 Zeilen) nicht bewusst geprüft; am 26. und 27.10. waren 17 bzw. 19 Pakete veraltet. Beim nächsten Öffnen des Panels mit vielen Paketen darauf achten.
- VS Code: Findet die Swift-Erweiterung `Packages/BrewCheck` von selbst (keine roten Fehler in den Quelldateien, Tests in der Seitenleiste)?
- Mitteilungs-Erlaubnis: Warum nach dem ersten Erteilen ein Neustart nötig war, ist ungeklärt; der Wortlaut der Knöpfe im Banner fehlt. Beim ersten Start einer neuen Kopie in Phase 7b beobachten.
- Nicht von Hand getestet: Fehlerpfade von `UpgradeLauncher` (Skript nicht schreibbar, Terminal nicht zu öffnen; bei `cannotOpenScript` steht nur der Pfad im Log), Fehler von `register()`/`unregister()` und der Zustand `.requiresApproval` beim Login-Start, der Rückfall auf `x-apple.systempreferences:`.
- „Log öffnen“ tut nichts, wenn die Datei fehlt; der Rückgabewert von `NSWorkspace.open` wird nicht ausgewertet.
- Ein `checkInterval` außerhalb der Auswahl (z. B. 180 aus Tests) lässt das Auswahlfeld leer; nach Tests mit `defaults delete io.github.muunleit-projects.thetap checkInterval` zurücksetzen.
- Eine geänderte Einstellung „Casks mit eigenem Updater“ wirkt erst ab der nächsten Prüfung; die angezeigte Liste bleibt bis dahin stehen.
- Intel: Die Release-Kopie enthält `x86_64`, wurde aber nie auf einem Intel-Mac gestartet.
- Offene Entscheidungen stehen in `PLAN.md` unter „Offene Punkte“ (Quarantäne im Cask, Updates mit Ad-hoc-Signierung, Standardwerte).

## Nächster Schritt

1. **Phase 6, Schritt 6 – Woche Alltag (28.10. bis 08.11.2026):** Die Kopie in `/Applications` normal benutzen, nichts bauen und nichts an `/Applications/TheTap.app` ändern. Auffälligkeiten oben unter „Auffälligkeiten in der Woche Alltag“ notieren.
2. **Nach dem 08.11.2026:** Die Liste der Auffälligkeiten durchgehen und entscheiden, was gebaut wird (darunter die Behandlung des Upgrade-Abbruchs) und ob eine zweite Testwoche folgt. Die Standardwerte prüfen (Prüfintervall 6 Stunden, `--greedy` an), bestätigen oder anpassen und die letzte Abnahme von Phase 6 abhaken. Danach kommt Phase 6 als abgenommen in `PLAN.md` unter „Abgeschlossene Phasen“, und `STATUS.md` wird gekürzt.
3. **Danach Phase 7b, Schritt 1:** Homebrew-Tap anlegen und den Schritt „Checksum“ in `release.yml` ergänzen (`RELEASE.md`, „Homebrew-Tap“). Erst nach der Woche, weil Phase 7b die Alltagskopie in `/Applications` ersetzt.

Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`. Für die Behandlung des Upgrade-Abbruchs zusätzlich `SPEC.md`, die Datei mit `UpgradeScript` und ihre Tests (`UpgradeScriptTests`). Für Phase 7b zusätzlich `RELEASE.md` (und `.github/workflows/release.yml`, falls der Schritt „Checksum“ noch fehlt).
