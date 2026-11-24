# TheTap – Status

Stand: 24.11.2026

## Aktuelle Phase

Phase 6, Schritt 6 – eine Woche Alltag, **Beginn 28.10.2026, Ende Sonntag 08.11.2026**; die Woche ist vorbei, die Abnahme steht aus. Schritte 1 bis 5 sind abgeschlossen. Phase 7a ist vorgezogen und abgenommen. Danach folgen Phase 7b (Update-Test über den eigenen Homebrew-Tap) und Phase 8. Ob nach der Woche eine zweite Testwoche folgt, entscheidet der Nutzer anhand der Liste unter „Auffälligkeiten in der Woche Alltag“.

## Umgebung

- Repo: https://github.com/muunleit-projects/TheTap (Branch `main`), lokal unter `~/Programmieren/swift/TheTap`. Letzter Commit vor dieser Aktualisierung: `b7bc7ce` („Document recheck traps in upgrade script“); die CI ist dafür und für `68763bb` grün.
- Mac: macOS 26, Xcode 27.1, Swift 6.4, xcodegen 2.46.0, Homebrew 7.0.9, git 2.54.0. brew liegt unter `/opt/homebrew/bin/brew` (normale Datei, kein Symlink). VS Code mit der Swift-Erweiterung (swiftlang).
- CI: Runner `macos-26` mit Xcode 26.6 und Swift 6.3.3 (älter als der Mac).
- Release: `release.yml` liegt im Repo und lief einmal grün; der Schritt „Checksum“ fehlt dort noch. Es gibt keinen Release; `v0.1.0-test.1` ist verbraucht.
- Tests: 81 Tests in 7 Suites, lokal (auch mit `HOMEBREW_NO_AUTO_UPDATE=1`) und in der CI grün.
- Im Alltag läuft `/Applications/TheTap.app`, am 24.11.2026 mit `scripts/install.sh` neu installiert (nur `arm64`, enthält die Traps im Upgrade-Skript); „Beim Anmelden starten“ ist an. `checkInterval` ist nicht gesetzt (Standard 6 Stunden) oder steht auf dem zuletzt im Einstellungsfenster gewählten Wert.
- Claude kann Dateien aus dem GitHub-Repo nicht selbst lesen. Der Nutzer lädt sie hoch oder das ganze Repo als ZIP.

## Zuletzt erledigt

- 24.11.2026, Abbruch des Upgrades behandelt (`68763bb`, Doku `b7bc7ce`): Das Upgrade-Skript sendet den Recheck einmal pro Lauf (Flag `rechecked`), am normalen Ende vor dem Tastendruck oder über `trap … EXIT` beim Schließen des Fensters bzw. `trap '…; exit 130' INT` bei Strg+C. Handproben bestanden: Strg+C, Fenster schließen, normales Ende (jeweils ein Recheck im Systemlog). `SPEC.md` und `README.md` angepasst. Beobachtet: Mit dem alten Skript blieb „Upgrade läuft im Terminal …“ nach Strg+C und nach dem Schließen des Fensters stehen.
- 24.11.2026, beobachtet: Laufen Debug-Build und `/Applications`-Kopie nebeneinander, startet `thetap://recheck` die Kopie in `/Applications` neu, der Debug-Build bekommt ihn nie (siehe „Nie zwei Kopien gleichzeitig“ in der README).
- 28.10.2026, `.gitignore` angepasst (`eb0b7ae`) und Dokumente neu geordnet (`2842f3e`, `d428642`, `2ad2769`).
- 27.10.2026, Entscheidungen des Nutzers (in `PLAN.md` eingetragen): eigener Homebrew-Tap, Phase 7b läuft darüber, die Alltagskopie kommt danach nur noch über brew; ein Icon in Mitteilungen ist nicht nötig; die Arbeitsweise bleibt beim Free-Plan.
- 27.10.2026, Homebrew geprüft: Das offizielle Cask-Repo nimmt TheTap nicht auf (Gatekeeper-Pflicht, Mindestzahl an Sternen).

## Auffälligkeiten in der Woche Alltag

Der Nutzer trägt hier ein, was ihm aufgefallen ist (Datum, was passiert ist, wie es sich zeigt). Danach wird die Liste durchgegangen: Was wird gebaut, was bleibt, folgt eine zweite Testwoche?

- Abbruch des Upgrades: erledigt (24.11.2026, siehe oben).
- Weitere Auffälligkeiten: noch nicht eingetragen.

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

1. **Phase 6, Schritt 6 abschließen:** Die Auffälligkeiten der Woche (28.10. bis 08.11.2026) oben eintragen und durchgehen, entscheiden, was gebaut wird und ob eine zweite Testwoche folgt. Die Standardwerte prüfen (Prüfintervall 6 Stunden, `--greedy` an), bestätigen oder anpassen und die letzte Abnahme von Phase 6 abhaken. Danach kommt Phase 6 als abgenommen in `PLAN.md` unter „Abgeschlossene Phasen“, und `STATUS.md` wird gekürzt.
2. **Danach Phase 7b, Schritt 1:** Homebrew-Tap anlegen und den Schritt „Checksum“ in `release.yml` ergänzen (`RELEASE.md`, „Homebrew-Tap“). Phase 7b ersetzt die Alltagskopie in `/Applications`.

Im neuen Chat hochladen: `PLAN.md`, `STATUS.md`. Für Phase 7b zusätzlich `RELEASE.md` und `.github/workflows/release.yml`.
