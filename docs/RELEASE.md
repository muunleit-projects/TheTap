# TheTap – Release über GitHub

Anleitung für Phase 7a und für jeden späteren Release. Sie gehört zu `docs/PLAN.md`; dessen Arbeitsregeln gelten auch hier. Der Nutzer lädt diese Datei nur hoch, wenn Phase 7a oder ein Release dran ist.

GitHub Actions baut die App bei jedem Versions-Tag als Release-Build und hängt sie als ZIP an einen GitHub-Release; andere laden sie dort unter „Releases“ herunter. Gebaut wird nur auf GitHub, den Mac braucht der Nutzer nur zum Testen des Downloads. Die App ist ad hoc signiert und nicht notarisiert (kein Apple Developer Program). Deshalb blockiert macOS sie beim ersten Start, bis der Nutzer sie in den Systemeinstellungen freigibt.

Die Dateiinhalte hier sind fertig ausgearbeitet und mit `actionlint` geprüft, aber noch nie auf GitHub gelaufen. Übernimm sie wörtlich und ändere sie nur, wenn ein Lauf fehlschlägt. Sobald `release.yml` im Repo liegt und ein Lauf grün war, ersetzt du den YAML-Block hier durch einen Verweis auf die Datei.

Solange Phase 6 nicht abgehakt ist, gibt es nur Vorabversionen: Tags mit Bindestrich, z. B. `v0.1.0-test.1` oder `v0.2.0-beta.1`. Der Workflow markiert sie als „Pre-release“ und schreibt nur den Teil vor dem Bindestrich als Version in die App, weil macOS dort drei durch Punkte getrennte Zahlen erwartet. Bis Phase 6 abgehakt ist und die App eine Woche im Alltag lief, beginnen die Versionen mit `0.`; danach folgt `v1.0.0`.

**Schritt 1 – Versionsnummer aus den Build-Einstellungen**

Ohne Angabe schreibt XcodeGen fest `1.0` und `1` in `App/Info.plist` (geprüft am 20.10.2026 im Quelltext von XcodeGen, `InfoPlistGenerator.swift`). `MARKETING_VERSION: "0.1.0"` aus `project.yml` kommt bisher also nicht in der App an. In `project.yml` unter `targets → TheTap → info → properties` direkt nach `CFBundleDisplayName: TheTap` diese zwei Zeilen ergänzen (die KI gibt `project.yml` wie immer vollständig aus):

```yaml
CFBundleShortVersionString: '$(MARKETING_VERSION)'
CFBundleVersion: '$(CURRENT_PROJECT_VERSION)'
```

Prüfen:

1. `scripts/build.sh` endet mit `** BUILD SUCCEEDED **`.
2. `git diff App/Info.plist` zeigt: `1.0` ist durch `$(MARKETING_VERSION)` ersetzt, `1` durch `$(CURRENT_PROJECT_VERSION)`. Die geänderte `Info.plist` wird mit committet.
3. `plutil -extract CFBundleShortVersionString raw build/Build/Products/Debug/TheTap.app/Contents/Info.plist` gibt `0.1.0` aus.

Commit: `Take app version from build settings`.

**Schritt 2 – Release-Workflow**

Neue Datei `.github/workflows/release.yml`:

```yaml
name: Release

# Runs when a version tag like v0.2.0 is pushed. Builds a universal
# Release app, zips it and attaches the zip to a GitHub Release.
# Tags with a hyphen (v0.2.0-test.1) become pre-releases.
on:
    push:
        tags: ['v*']

permissions:
    contents: write

jobs:
    release:
        name: Build and publish (macOS 26)
        runs-on: macos-26
        env:
            APP: build/Build/Products/Release/TheTap.app
        steps:
            - uses: actions/checkout@v5

            - name: Read version from tag
              run: |
                  VERSION="${GITHUB_REF_NAME#v}"
                  echo "VERSION=$VERSION" >> "$GITHUB_ENV"
                  echo "BUNDLE_VERSION=${VERSION%%-*}" >> "$GITHUB_ENV"

            - name: Run package tests
              working-directory: Packages/BrewCheck
              run: swift test

            - name: Install XcodeGen
              run: brew install xcodegen

            - name: Build app (Release, Apple Silicon + Intel)
              run: |
                  xcodegen generate
                  xcodebuild \
                      -project TheTap.xcodeproj \
                      -scheme TheTap \
                      -configuration Release \
                      -destination "generic/platform=macOS" \
                      -derivedDataPath build \
                      ARCHS="arm64 x86_64" \
                      MARKETING_VERSION="$BUNDLE_VERSION" \
                      CURRENT_PROJECT_VERSION="$GITHUB_RUN_NUMBER" \
                      build

            - name: Check build
              run: |
                  echo "Version: $(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
                  echo "Architectures: $(lipo -archs "$APP/Contents/MacOS/TheTap")"
                  codesign --verify --deep --strict "$APP"
                  codesign -dv "$APP" 2>&1 | grep -E "Identifier|Signature"

            - name: Zip app
              run: ditto -c -k --sequesterRsrc --keepParent "$APP" "TheTap-$VERSION.zip"

            - name: Publish GitHub Release
              env:
                  GH_TOKEN: ${{ github.token }}
              run: |
                  args=(--title "TheTap $VERSION" --generate-notes --verify-tag)
                  if [[ "$VERSION" == *-* ]]; then
                      args+=(--prerelease)
                  fi
                  gh release create "$GITHUB_REF_NAME" "TheTap-$VERSION.zip" "${args[@]}"
```

- Auslöser sind nur Tags, die mit `v` beginnen. Ein normaler Push auf `main` startet weiterhin nur `ci.yml`.
- `permissions: contents: write` erlaubt dem Workflow, den Release anzulegen.
- Vor dem Build läuft `swift test`; ein roter Test verhindert den Release.
- `ARCHS="arm64 x86_64"` zusammen mit `-destination "generic/platform=macOS"` ergibt eine App für Apple Silicon und Intel. Die Build-Nummer ist die laufende Nummer des Workflows.
- „Check build“ gibt Version, Architekturen und Signatur aus und bricht ab, wenn die Signatur ungültig ist.
- `ditto` packt das App-Bundle samt Symlinks und Metadaten; das ist Apples empfohlener Weg, eine App zu zippen.
- `gh` (GitHub CLI) ist auf den Runnern vorinstalliert. `GH_TOKEN` ist der automatische Schlüssel des Laufs; ein eigenes Secret ist nicht nötig.

Commit: `Add release workflow`, danach pushen. Dabei entsteht noch kein Release, es läuft nur die normale CI.

**Schritt 3 – Testrelease**

Wenn die CI auf `main` grün ist:

```
git tag v0.1.0-test.1
git push origin v0.1.0-test.1
```

1. Auf GitHub das Repo öffnen und oben auf den Reiter „Actions“ klicken.
2. Links „Release“ wählen. Oben steht ein Lauf mit dem Namen des Tags; er dauert einige Minuten.
3. Ist er rot: den roten Schritt aufklappen und der KI die letzten etwa 40 Zeilen schicken.
4. Ist er grün: den Schritt „Check build“ aufklappen. Erwartet werden `Version: 0.1.0`, bei `Architectures:` sowohl `x86_64` als auch `arm64`, eine Zeile `Identifier=io.github.muunleit-projects.thetap` und `Signature=adhoc`. Diese Zeilen der KI melden.
5. Zurück zur Startseite des Repos: Rechts unter „Releases“ steht „TheTap 0.1.0-test.1“ mit dem Etikett „Pre-release“ und der Datei `TheTap-0.1.0-test.1.zip`.

**Schritt 4 – Download auf dem Mac testen**

Die heruntergeladene App hat dieselbe Bundle-ID wie der lokale Build. Damit sich beide nicht in die Quere kommen (zwei Icons, `thetap://recheck` landet in der falschen App), läuft während des Tests nur die heruntergeladene App.

1. Die laufende TheTap im Panel über „Beenden“ schließen.
2. Im Browser auf der Release-Seite `TheTap-0.1.0-test.1.zip` herunterladen.
3. Im Finder den Ordner „Downloads“ öffnen und die ZIP doppelklicken; daneben entsteht `TheTap.app`. Diese in den Ordner „Programme“ ziehen.
4. `TheTap.app` in „Programme“ doppelklicken. macOS zeigt eine Warnung und öffnet die App nicht. Den genauen Text der Warnung und die Beschriftung der Knöpfe notieren.
5. Apple-Menü → „Systemeinstellungen …“ → links „Datenschutz & Sicherheit“ → ganz nach unten scrollen bis zum Abschnitt „Sicherheit“. Dort steht ein Hinweis zu TheTap mit einem Knopf zum Öffnen (englisch „Open Anyway“, deutsch vermutlich „Dennoch öffnen“; genaue Beschriftung notieren). Klicken, mit Passwort oder Touch ID bestätigen und im folgenden Dialog „Öffnen“ wählen.
6. Prüfen: Das Icon erscheint in der Menüleiste, „Jetzt prüfen“ zeigt die Pakete, „Alles aktualisieren“ öffnet das Terminal und danach aktualisiert sich die Liste.
7. Die App über „Beenden“ schließen und erneut doppelklicken: Sie startet jetzt ohne Warnung.
8. Gegenprobe für den Weg über das Terminal: `TheTap.app` in den Papierkorb legen, die ZIP erneut entpacken und die App nach „Programme“ ziehen. Dann im Terminal `xattr -dr com.apple.quarantine /Applications/TheTap.app` ausführen und die App doppelklicken. Erwartet: Sie startet ohne Warnung.
9. Zum Schluss `TheTap.app` aus „Programme“ in den Papierkorb legen und mit lokalen Builds (`scripts/run.sh`) weiterarbeiten. Ist Phase 6 schon abgeschlossen, stattdessen `scripts/install.sh` ausführen.

**Schritt 5 – README**

In `README.md` den Satz „Sie ist nur für den Eigengebrauch auf einem Mac gedacht.“ anpassen und einen Abschnitt „Herunterladen und installieren“ ergänzen:

- Voraussetzungen: macOS 26 und Homebrew.
- Download: die neueste `TheTap-….zip` unter „Releases“.
- Installation: ZIP entpacken, `TheTap.app` in den Ordner „Programme“ ziehen.
- Erster Start: Warum macOS warnt (ad hoc signiert, nicht notarisiert, kein Apple-Developer-Konto), dann die Freigabe mit den in Schritt 4 notierten echten Texten; alternativ der `xattr`-Befehl aus Schritt 4.
- Update: die neue Version herunterladen und die alte in „Programme“ ersetzen. Ob die Freigabe dann erneut nötig ist, klärt Phase 7b.

Commit: `Describe download and installation in README`.

**Schritt 6 – Testrelease löschen**

1. Auf GitHub rechts unter „Releases“ den Eintrag „TheTap 0.1.0-test.1“ öffnen, auf das Papierkorb-Symbol klicken und das Löschen bestätigen.
2. Den Tag löschen: `git push --delete origin v0.1.0-test.1` und danach `git tag -d v0.1.0-test.1`.

**Ablauf für jeden späteren Release**

1. Die gewünschte Phase ist abgehakt, die CI auf `main` ist grün.
2. In `project.yml` `MARKETING_VERSION` auf die neue Nummer setzen (`CURRENT_PROJECT_VERSION` bleibt `"1"`; im Release setzt der Workflow die Build-Nummer). `scripts/build.sh` ausführen, Commit `Bump version to 0.2.0`, pushen.
3. Taggen und pushen: `git tag v0.2.0-beta.1` und `git push origin v0.2.0-beta.1` (nach Abschluss von Phase 6 ohne Zusatz, z. B. `v1.0.0`).
4. Den Lauf „Release“ prüfen wie in Schritt 3. Den automatisch erzeugten Release-Text kann der Nutzer auf der Release-Seite über das Stift-Symbol ergänzen.
5. Ein Tag wird nie wiederverwendet. Schlägt ein Release fehl: Fehler beheben, den fehlgeschlagenen Tag wie in Schritt 6 löschen und eine neue Nummer taggen (z. B. `v0.2.0-beta.2`).

Die Abnahmekriterien stehen in `docs/PLAN.md` unter Phase 7a.
