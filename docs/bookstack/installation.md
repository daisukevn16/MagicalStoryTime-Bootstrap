# Fresh-Server-Installation von MagicalStoryTime

## Zweck

Dieses öffentliche Bootstrap-Repository löst ausschließlich das Henne-Ei-Problem einer privaten Anwendung: Auf einem komplett neuen Server existiert noch keine `MagicalStoryTime/Bootstrap.sh` oder `Updater.sh`, gleichzeitig ist das eigentliche Repository privat und benötigt einen Fine-grained GitHub Token.

Der öffentliche `install.sh` stellt deshalb nur den authentifizierten Erstkontakt her. Danach übernimmt das private MagicalStoryTime-Repository vollständig.

## Standardaufruf für main

```bash
curl -fsSL https://raw.githubusercontent.com/daisukevn16/MagicalStoryTime-Bootstrap/main/install.sh \
  | sudo bash
```

## Test-/Feature-Branch

```bash
curl -fsSL https://raw.githubusercontent.com/daisukevn16/MagicalStoryTime-Bootstrap/main/install.sh \
  | sudo bash -s -- agent/item-link-definitions-280 v0.7.1031-alpha
```

Das erste Argument ist der private MagicalStoryTime-Branch. Das optionale zweite Argument ist die erwartete MagicalStoryTime-Version, die an die private Installationskette weitergereicht wird.

## Benötigter GitHub Token

Empfohlen wird ein Fine-grained Personal Access Token mit möglichst kleinem Scope:

- Repository-Zugriff nur auf `daisukevn16/MagicalStoryTime`
- Repository permission `Contents: Read-only`

Der öffentliche Installer fragt den Token nur dann ab, wenn `/etc/magical-story-time/github-token` noch nicht vorhanden bzw. leer ist.

Die Eingabe erfolgt verdeckt über `/dev/tty`. Dadurch bleibt die Abfrage auch bei `curl | sudo bash` interaktiv und der Token wird nicht aus dem Pipe-Standardinput gelesen.

## Ablauf

1. `install.sh` prüft root-Rechte und Debian/Ubuntu.
2. `curl` und CA-Zertifikate werden bei Bedarf installiert.
3. `/etc/magical-story-time` wird mit Modus `0700` vorbereitet.
4. Ein vorhandener GitHub Token wird wiederverwendet; andernfalls erfolgt eine verdeckte Abfrage.
5. Eine temporäre curl-Konfiguration mit Modus `0600` enthält den Authorization-Header.
6. Die private Datei `MagicalStoryTime/Bootstrap.sh` wird für den angeforderten Branch über die GitHub Contents API geladen.
7. Der Download wird auf erwartetes Bash-/MagicalStoryTime-Format geprüft.
8. Ein neu eingegebener Token wird erst jetzt als `/etc/magical-story-time/github-token` mit Modus `0600` gespeichert.
9. Die private `Bootstrap.sh` wird mit Branch und optionaler Zielversion aufgerufen.
10. Diese übernimmt Git-Checkout, private Git-Authentifizierung, Docker, Portainer, Stack, Initial-Anwendungszugangsdaten und danach die versionierte `Updater.sh`.
11. Temporäre öffentliche Bootstrap-Dateien werden entfernt.

## Sicherheitsgrenzen

Der öffentliche Installer darf niemals:

- MagicalStoryTime-Secrets fest einbauen,
- den GitHub Token in einer URL speichern,
- den GitHub Token in der Terminalausgabe anzeigen,
- den GitHub Token in das öffentliche Repository schreiben,
- eine eigene Portainer-/Docker-Deploymentlogik neben dem privaten Updater etablieren,
- eine vorhandene Token-Datei bei einem Downloadfehler automatisch löschen oder ersetzen.

Ein neu eingegebener Token wird bei fehlgeschlagenem privaten Zugriff nicht dauerhaft gespeichert.

## Persistente lokale Datei

Nach erfolgreichem Erstzugriff existiert:

```text
/etc/magical-story-time/github-token
```

Erwartete Rechte:

```text
root:root 0600
```

Diese Datei wird von der privaten `Bootstrap.sh` und `Updater.sh` für spätere authentifizierte Git-Zugriffe wiederverwendet.

## Nach erfolgreicher Erstinstallation

Der öffentliche Installer wird für normale Updates nicht mehr benötigt. Standard ist dann:

```bash
sudo bash /opt/MagicalStoryTime/Updater.sh main
```

oder für einen Entwicklungsbranch:

```bash
sudo bash /opt/MagicalStoryTime/Updater.sh agent/item-link-definitions-280
```

## Abnahme

Die Repository-Implementierung allein ist noch kein Nachweis für einen erfolgreichen Fresh Install. Das zugehörige Issue bleibt offen, bis der Ablauf auf einem tatsächlich neuen Debian-/Ubuntu-System erfolgreich bis zum privaten MagicalStoryTime-Updater ausgeführt wurde.
