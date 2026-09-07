# MagicalStoryTime Bootstrap

Öffentlicher Minimal-Installer für das private Repository `daisukevn16/MagicalStoryTime`.

Aktuelle Bootstrap-Version: `v0.1.1-alpha`

Dieses Repository enthält **keinen MagicalStoryTime-Anwendungscode und keine Secrets**. `install.sh` stellt nur den sicheren Erstkontakt zum privaten Repository her und übergibt anschließend an die dort versionierte `Bootstrap.sh` und `Updater.sh`.

## Voraussetzungen

- Debian oder Ubuntu
- `root`-/`sudo`-Rechte
- Internetzugriff auf GitHub
- ein GitHub Fine-grained Personal Access Token mit Zugriff auf das private Repository `daisukevn16/MagicalStoryTime`
- für den Token mindestens Repository-Berechtigung **Contents: Read-only**

## Fresh Install – main

Auf einem komplett neuen System ohne vorhandenen MagicalStoryTime-Checkout:

```bash
curl -fsSL https://raw.githubusercontent.com/daisukevn16/MagicalStoryTime-Bootstrap/main/install.sh \
  | sudo bash
```

`install.sh` fragt den GitHub Fine-grained Token verdeckt direkt über das Terminal ab. Dadurch funktioniert die Abfrage auch dann, wenn das Script über eine Pipe an `bash` übergeben wird.

Nach erfolgreicher Authentifizierung wird die private `Bootstrap.sh` aus `MagicalStoryTime` geladen. Diese übernimmt anschließend Repository-Clone, Docker-/Portainer-Vorbereitung, Stack-Erstellung, Initial-Zugangsdaten und die Übergabe an `Updater.sh`.

## Installation eines bestimmten Branches

Für einen Feature-/Test-Branch:

```bash
curl -fsSL https://raw.githubusercontent.com/daisukevn16/MagicalStoryTime-Bootstrap/main/install.sh \
  | sudo bash -s -- agent/item-link-definitions-280
```

Optional kann als zweites Argument eine erwartete MagicalStoryTime-Version übergeben werden:

```bash
curl -fsSL https://raw.githubusercontent.com/daisukevn16/MagicalStoryTime-Bootstrap/main/install.sh \
  | sudo bash -s -- agent/item-link-definitions-280 v0.7.1042-alpha
```

## Was der öffentliche Installer macht

1. prüft, dass er als `root` läuft;
2. unterstützt bewusst nur Debian/Ubuntu für die automatische Erstinstallation;
3. stellt `curl` und CA-Zertifikate sicher;
4. legt `/etc/magical-story-time` mit restriktiven Rechten an;
5. verwendet einen vorhandenen `/etc/magical-story-time/github-token` oder fragt den Fine-grained Token verdeckt über `/dev/tty` ab;
6. lädt die private `Bootstrap.sh` authentifiziert über die GitHub Contents API;
7. speichert einen neu eingegebenen Token erst nach erfolgreichem privaten Zugriff;
8. übergibt Branch und optionale Zielversion an die private `Bootstrap.sh`;
9. entfernt seine temporären Authentifizierungs- und Bootstrap-Dateien wieder.

## Sicherheitsregeln

- Der GitHub Token steht nicht in der öffentlichen Repository-Datei.
- Der Token wird nicht in der Git-Remote-URL gespeichert.
- Der Authorization-Header wird nicht als sichtbares curl-Kommandozeilenargument übergeben.
- Temporäre curl-Konfigurationen und Bootstrap-Dateien werden mit restriktiven Rechten angelegt und nach dem Lauf entfernt.
- Der restriktive `umask` für Secret-Dateien ist auf den jeweiligen Schreibvorgang begrenzt und wird nicht in den privaten Repository-Checkout vererbt.
- Ein neu eingegebener Token wird erst gespeichert, nachdem der authentifizierte Zugriff auf die private `Bootstrap.sh` erfolgreich war.
- Eine bereits vorhandene Token-Datei wird bei einem Fehler nicht automatisch gelöscht oder überschrieben.
- Der öffentliche Installer führt keine Docker-/Portainer-Deploymentlogik selbst aus; diese Verantwortung bleibt im privaten, versionierten MagicalStoryTime-Repository.

## Nach der Erstinstallation

Nach erfolgreichem Bootstrap wird für normale Updates ausschließlich die private MagicalStoryTime-`Updater.sh` verwendet:

```bash
sudo bash /opt/MagicalStoryTime/Updater.sh main
```

Für einen Entwicklungsbranch entsprechend:

```bash
sudo bash /opt/MagicalStoryTime/Updater.sh agent/item-link-definitions-280
```

## Dokumentation

Weitere Details zum Ablauf stehen unter `docs/bookstack/installation.md`.

## Tracking

Die initiale Implementierung wird in Issue `#1` dieses Repositories verfolgt. Der reale Fresh-Server-Test ist Teil der Abnahme und wird nicht durch einen reinen Repository-Review ersetzt.
