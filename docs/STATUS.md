# TheTap – Status

Stand: 24.11.2026

## Aktuelle Phase

Phase 7b, Schritt 2 – Update-Test über einen eigenen Homebrew-Tap. Schritt 1 ist erledigt. Phase 6 und Phase 7a sind abgenommen. Danach folgt Phase 8.

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Letzter Commit vor dieser Aktualisierung: `f9d9705` („Print checksum of release zip“); die CI ist grün (nach einem Re-Run, der erste Lauf hing in der Runner-Warteschlange).
- Tap-Repo: https://github.com/muunleit-projects/homebrew-tap (öffentlich), lokal unter `~/Programmieren/homebrew-tap`. Bisher nur `README.md` (Commit `4dede7e`, „Initial commit“); `Casks/thetap.rb` fehlt noch.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0. brew liegt unter `/opt/homebrew/bin/brew` (normale Datei, kein Symlink). VS Code mit der Swift-Erweiterung (swiftlang).
- CI: Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3 (älter als der Mac).
- Release: `release.yml` liegt im Repo und lief einmal grün; der Schritt „Checksum“ ist ergänzt, aber noch nie gelaufen. Es gibt keinen Release; `v0.1.0-test.1` ist verbraucht.
- Tests: 81 Tests in 7 Suites, lokal (auch mit `HOMEBREW_NO_AUTO_UPDATE=1`) und in der CI grün.
- Im Alltag läuft `/Applications/TheTap.app`, am 24.11.2026 mit `scripts/install.sh` installiert (nur `arm64`); „Beim Anmelden starten“ ist an. Phase 7b ersetzt diese Kopie durch die Installation über brew.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen. Der Nutzer lädt sie hoch oder das ganze Repo als ZIP.

## Zuletzt erledigt

- 24.11.2026, Phase 7b, Schritt 1: `brew info --cask thetap` meldet, dass es kein Cask dieses Namens gibt (Name frei); Schritt „Checksum“ in `release.yml` ergänzt (`f9d9705`); Tap-Repo angelegt und geklont.
- 24.11.2026, Phase 6 abgenommen (Standardwerte bestätigt, `1297ba4`).

## Offene Probleme

- Der Schritt „Checksum“ in `release.yml` ist ungetestet; der erste Lauf folgt mit `v1.0.0-beta.1`.
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

1. **Phase 7b, Schritt 2a:** `MARKETING_VERSION` in `project.yml` auf `1.0.0` setzen, `scripts/build.sh`, Commit `Bump version to 1.0.0`, pushen, CI abwarten, dann `v1.0.0-beta.1` taggen und pushen (`RELEASE.md`, „Ablauf“). Aus dem Lauf die SHA-256 aus „Checksum“ notieren.
2. **Phase 7b, Schritt 2b:** `Casks/thetap.rb` im Tap anlegen, `brew audit`, TheTap beenden, `/Applications/TheTap.app` in den Papierkorb, installieren (siehe `PLAN.md`).

Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`, `RELEASE.md` und `project.yml`.
