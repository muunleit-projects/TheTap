# TheTap

TheTap ist eine Menüleisten-App für macOS, die veraltete Homebrew-Pakete anzeigt. Über die App kannst du Homebrew nach Updates suchen lassen und ausgewählte Upgrades im Terminal starten.

## Funktionen

- Zeigt veraltete Homebrew-Formulae und Casks in der Menüleiste an.
- Listet installierte und aktuelle Versionen auf; angepinnte Pakete werden gekennzeichnet und nicht als upgradefähig gezählt.
- Prüft Homebrew manuell über **„Jetzt prüfen“**. Dabei werden zunächst die Homebrew-Daten aktualisiert.
- Startet über **„Alles aktualisieren“** ein Upgrade im Terminal. Die Prüfung umfasst auch Casks mit eigenem Updater; angepinnte Pakete werden von Homebrew übersprungen.
- Erkennt, wenn keine Netzwerkverbindung besteht, und prüft bei wiederhergestellter Verbindung erneut.

## Voraussetzungen

- macOS 26 oder neuer
- [Homebrew](https://brew.sh/)
- Xcode Command Line Tools und Xcode
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Bauen und starten

Im Repository-Verzeichnis:

```sh
scripts/build.sh
```

Das Skript generiert das Xcode-Projekt aus `project.yml` und baut die App im Debug-Modus. Zum Bauen und direkten Starten der App:

```sh
scripts/run.sh
```

Alternativ lässt sich `TheTap.xcodeproj` in Xcode öffnen.

## Tests

Die Tests des `BrewCheck`-Pakets kannst du so ausführen:

```sh
swift test --package-path Packages/BrewCheck
```
