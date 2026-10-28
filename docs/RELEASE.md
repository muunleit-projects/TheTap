# TheTap – Release und Homebrew-Tap

Ablauf für jeden Release. Gehört zu `docs/PLAN.md`; dessen Arbeitsregeln gelten auch hier. Der Nutzer lädt diese Datei hoch, wenn ein Release oder der Homebrew-Tap dran ist.

## So funktioniert es

`.github/workflows/release.yml` startet bei jedem Tag, der mit `v` beginnt (erprobt am 27.10.2026, erster Lauf grün). Der Workflow testet das Package, baut die App als Release für Apple Silicon und Intel, gibt Version, Architekturen und Signatur aus, packt die App mit `ditto` als `TheTap-<Version>.zip` und legt einen GitHub-Release an. Die Datei im Repo ist maßgeblich; ändere sie nur, wenn ein Lauf fehlschlägt oder ein Schritt dazukommt.

- Tags mit Bindestrich (`v1.0.0-beta.1`) werden „Pre-release“. In die App kommt nur der Teil vor dem Bindestrich (`1.0.0`), weil macOS dort drei durch Punkte getrennte Zahlen erwartet. Die Build-Nummer (`CFBundleVersion`) ist die laufende Nummer des Workflows.
- Solange Phase 6 nicht abgehakt ist, gibt es nur Vorabversionen; danach `v1.0.0`.
- Ein Tag wird nie wiederverwendet. Bisher verbraucht: `v0.1.0-test.1` (Testrelease, gelöscht).
- Die App ist ad hoc signiert und nicht notarisiert. Heruntergeladen blockiert macOS sie beim ersten Start; die Freigabe steht in der README unter „Erster Start: Freigabe in macOS“.

## Ablauf

1. Die gewünschte Phase ist abgehakt, die CI auf `main` ist grün.
2. In `project.yml` `MARKETING_VERSION` auf die neue Nummer setzen, ohne Zusatz (z. B. `1.0.0` auch für `v1.0.0-beta.1`); `CURRENT_PROJECT_VERSION` bleibt `"1"`, im Release setzt der Workflow die Build-Nummer. `scripts/build.sh` ausführen, Commit `Bump version to 1.0.0`, pushen und die CI abwarten.
3. Taggen und pushen, z. B. `git tag v1.0.0-beta.1` und `git push origin v1.0.0-beta.1`.
4. Auf GitHub oben „Actions“ → links „Release“ → oberster Lauf; er dauert einige Minuten.
   - Rot: den roten Schritt aufklappen und der KI die letzten etwa 40 Zeilen schicken.
   - Grün: „Check build“ aufklappen. Erwartet: `Version:` mit der Nummer aus dem Tag (ohne Zusatz), `Architectures: x86_64 arm64`, `Identifier=io.github.muunleit-projects.thetap` und `Signature=adhoc`. Mit Tap zusätzlich „Checksum“ aufklappen und die SHA-256 notieren.
5. Startseite des Repos → rechts „Releases“: „TheTap <Version>“ mit `TheTap-<Version>.zip`, bei einem Tag mit Bindestrich mit dem Etikett „Pre-release“. Den automatisch erzeugten Text kann der Nutzer über das Stift-Symbol ergänzen.
6. **Download testen**, wenn sich am Build oder an der Signatur etwas geändert hat oder das Verhalten bei Updates noch offen ist: TheTap über „Beenden“ schließen, die ZIP herunterladen und im Finder doppelklicken, `TheTap.app` in „Programme“ ersetzen und starten, bei Bedarf freigeben. Prüfen: Icon in der Menüleiste, „Jetzt prüfen“, „Alles aktualisieren“. Notieren, ob die Freigabe nötig war und ob Mitteilungs-Erlaubnis und „Beim Anmelden starten“ erhalten blieben. Mit Tap läuft dieser Test über brew (unten).
7. Mit Tap: den Cask aktualisieren (unten, „Bei jedem Release“).

## Fehlgeschlagener Release

Fehler beheben und committen. Einen schon angelegten Release auf GitHub öffnen und über das Papierkorb-Symbol löschen. Den Tag löschen mit `git push --delete origin <tag>` und danach `git tag -d <tag>`. Dann eine neue Nummer taggen (z. B. `v1.0.0-beta.2`).

## Homebrew-Tap

Der Tap ist ein eigenes öffentliches Repo `muunleit-projects/homebrew-tap`, auf dem Mac z. B. unter `~/Programmieren/homebrew-tap`. Er enthält nur `Casks/thetap.rb` und eine kurze README. Ein **Tap** ist ein zusätzliches Paket-Verzeichnis für brew; ein **Cask** beschreibt, woher brew eine fertige Mac-App lädt und wohin es sie installiert. Nutzer installieren mit `brew install --cask muunleit-projects/tap/thetap`.

**Einmalig anlegen** (Phase 7b, Schritt 1):

1. Prüfen, dass der Name im offiziellen Repo frei ist: `brew info --cask thetap` soll melden, dass es kein solches Cask gibt.
2. In `.github/workflows/release.yml` nach dem Schritt „Zip app“ einfügen (Commit `Print checksum of release zip`):

   ```yaml
         - name: Checksum
           run: shasum -a 256 "TheTap-$VERSION.zip" | tee -a "$GITHUB_STEP_SUMMARY"
   ```

   Die Prüfsumme erscheint im Log des Schritts und in der Zusammenfassung des Laufs, sodass sie nicht von Hand gerechnet werden muss.
3. Auf GitHub ein neues öffentliches Repo `homebrew-tap` unter `muunleit-projects` anlegen (mit README) und auf den Mac klonen.
4. `Casks/thetap.rb` mit dem Grundgerüst unten anlegen, sobald der erste Release mit Prüfsumme existiert; committen und pushen.
5. `brew tap muunleit-projects/tap`, dann `brew audit --cask --strict muunleit-projects/tap/thetap`. Meldungen der KI schicken.

**Grundgerüst** (noch nie gelaufen; Maßstab ist `brew audit`):

```ruby
cask "thetap" do
  version "1.0.0-beta.1"
  sha256 "SHA-256 aus dem Schritt Checksum des Release-Laufs"

  url "https://github.com/muunleit-projects/TheTap/releases/download/v#{version}/TheTap-#{version}.zip"
  name "TheTap"
  desc "Menüleisten-App, die veraltete Homebrew-Pakete meldet"
  homepage "https://github.com/muunleit-projects/TheTap"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :tahoe

  app "TheTap.app"

  uninstall quit: "io.github.muunleit-projects.thetap"

  zap trash: [
    "~/Library/Logs/TheTap",
    "~/Library/Preferences/io.github.muunleit-projects.thetap.plist",
  ]

  caveats <<~EOS
    TheTap ist ad hoc signiert und nicht notarisiert. macOS blockiert die App
    beim ersten Start. Freigabe: Systemeinstellungen → Datenschutz & Sicherheit
    → „Dennoch öffnen“.
  EOS
end
```

- `uninstall quit:` beendet TheTap vor einem Upgrade mit dem Apple-Event „Beenden“ (wie Cmd+Q). Läuft das Upgrade aus TheTap heraus, startet danach `open -g "thetap://recheck"` aus dem Upgrade-Skript die neue Version. Zu prüfen: ob macOS dabei fragt, ob Terminal TheTap steuern darf.
- `zap` löscht bei `brew uninstall --zap --cask thetap` zusätzlich Einstellungen und Log.
- `depends_on macos: :tahoe`: ob das Symbol so heißt und „mindestens macOS 26“ bedeutet, zeigt `brew audit`.
- Bewusst kein `auto_updates true`: TheTap aktualisiert sich nicht selbst. So erscheint eine neue Version bei `brew outdated` auch ohne `--greedy`.
- `livecheck` mit `:github_latest` ignoriert Vorabversionen; `brew livecheck --cask muunleit-projects/tap/thetap` zeigt die neueste normale Version.

**Bei jedem Release** (nach Schritt 5 des Ablaufs):

1. Im Tap-Repo in `Casks/thetap.rb` `version` (Tag ohne `v`, z. B. `1.0.0`) und `sha256` (aus „Checksum“) ändern.
2. `brew audit --cask --strict muunleit-projects/tap/thetap`, Commit `thetap 1.0.0`, pushen.
3. Probe: `brew update`, dann `brew outdated --cask --greedy`; `thetap` erscheint mit der neuen Version. In TheTap zeigt „Jetzt prüfen“ dasselbe.
