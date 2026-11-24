# TheTap – Status

Stand: 24.11.2026

## Aktuelle Phase

Phase 7b, Schritt 1 – Update-Test über einen eigenen Homebrew-Tap. Phase 6 ist abgenommen (24.11.2026, Standardwerte bestätigt), Phase 7a ebenfalls. Danach folgt Phase 8.

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Letzter Commit vor dieser Aktualisierung: `a351d82` („Update status after recheck traps“); die CI ist grün.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0. brew liegt unter `/opt/homebrew/bin/brew` (normale Datei, kein Symlink). VS Code mit der Swift-Erweiterung (swiftlang).
- CI: Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3 (älter als der Mac).
- Release: `release.yml` liegt im Repo und lief einmal grün; der Schritt „Checksum“ fehlt dort noch. Es gibt keinen Release; `v0.1.0-test.1` ist verbraucht.
- Tests: 81 Tests in 7 Suites, lokal (auch mit `HOMEBREW_NO_AUTO_UPDATE=1`) und in der CI grün.
- Im Alltag läuft `/Applications/TheTap.app`, am 24.11.2026 mit `scripts/install.sh` installiert (nur `arm64`); „Beim Anmelden starten“ ist an. Phase 7b ersetzt diese Kopie durch die Installation über brew.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen. Der Nutzer lädt sie hoch oder das ganze Repo als ZIP.

## Zuletzt erledigt

- 24.11.2026, Phase 6 abgenommen: Woche Alltag (28.10. bis 08.11.2026) ohne Auffälligkeiten, Standardwerte bestätigt (Prüfintervall 6 Stunden, `--greedy` an), `PLAN.md` entsprechend angepasst.
- 24.11.2026, Abbruch des Upgrades behandelt (`68763bb`, Doku `b7bc7ce`): Das Upgrade-Skript sendet den Recheck einmal pro Lauf, auch bei Strg+C und beim Schließen des Fensters (siehe `SPEC.md`, „Upgrade (`UpgradeLauncher`)“).

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
- Offene Entscheidungen stehen in `PLAN.md` unter „Offene Punkte“ (Quarantäne im Cask, Updates mit Ad-hoc-Signierung).

## Nächster Schritt

1. **Phase 7b, Schritt 1:** Prüfen, dass der Name im offiziellen Repo frei ist (`brew info --cask thetap`), den Schritt „Checksum“ in `.github/workflows/release.yml` ergänzen, das Repo `muunleit-projects/homebrew-tap` anlegen und klonen. Anleitung in `RELEASE.md`, „Homebrew-Tap“. Das Ersetzen der Alltagskopie in `/Applications` folgt erst in Schritt 2.
2. **Phase 7b, Schritt 2:** `v1.0.0-beta.1` veröffentlichen, Cask anlegen und installieren (siehe `PLAN.md`).

Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`, `RELEASE.md` und `.github/workflows/release.yml`.
