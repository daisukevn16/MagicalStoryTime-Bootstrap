# MagicalStoryTime-Bootstrap – Struktur

Dieses Repository ist bewusst klein und enthält nur den öffentlichen Einstieg in die private MagicalStoryTime-Installation.

## Dateien

- `install.sh` – öffentlicher Fresh-Server-Einstieg. Fragt bei Bedarf den Fine-grained GitHub Token sicher ab, lädt die private `MagicalStoryTime/Bootstrap.sh` authentifiziert und übergibt anschließend die Installation an das private Repository.
- `VERSION` – Versionsmarker des öffentlichen Bootstrap-Repositories.
- `README.md` – Kurzstart, Token-Anforderungen, Sicherheitsregeln und Beispielaufrufe.
- `docs/bookstack/installation.md` – ausführlichere Betriebs- und Sicherheitsdokumentation für den Fresh-Install-Pfad.

## Ownership-Grenze

Dieses Repository besitzt ausdrücklich **keine** Verantwortung für:

- MagicalStoryTime-Anwendungscode,
- Docker-/Portainer-Stack-Lifecycle,
- Laufzeitkonfiguration,
- Anwendungs-Initial-Username/-Passwort,
- Datenmigration,
- Runtime-Tests oder Versionsverifikation der Anwendung.

Diese Verantwortung beginnt nach dem authentifizierten Download der privaten `Bootstrap.sh` und liegt vollständig im privaten Repository `daisukevn16/MagicalStoryTime`.

Dadurch bleibt der öffentliche Bootstrap klein, prüfbar und ohne private Implementierungsdetails.
