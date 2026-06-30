# Neue Role hinzufügen

Anleitung zum Hinzufügen eines neuen Services zum HomeLab-Repo.

## Voraussetzungen

```bash
cd ~/lab/HomeLab
export BW_SESSION=$(bw unlock --raw)
```

## Schritt 1: Service ganz normal einrichten

Installiere und konfiguriere den Service wie gewohnt über die Web-UI, SSH oder wie auch immer üblich. Erst wenn alles läuft und fertig konfiguriert ist, geht es weiter.

## Schritt 2: Inventory ergänzen

Falls der neue Host noch nicht im Inventory steht, in `inventory/production.yml` ergänzen:

```yaml
lxc:
  hosts:
    immich:
      ansible_host: 192.168.178.XXX
      ansible_user: root
```

## Schritt 3: SSH-Key auf den neuen Host bringen

```bash
ssh-add -L > /tmp/k.pub
ssh-copy-id -f -i /tmp/k.pub root@192.168.178.XXX
```

Verbindung testen:

```bash
ansible immich -m ping
```

## Schritt 4: Grundgerüst der Role erzeugen

```bash
./scripts/new-role.sh <rollenname> <inventory-gruppe>
```

Beispiel:

```bash
./scripts/new-role.sh immich immich
```

Das Script legt automatisch an:

* `roles/<rollenname>/tasks/main.yml`
* `roles/<rollenname>/handlers/main.yml`
* `roles/<rollenname>/templates/config.yml.j2`
* `host_vars/<inventory-gruppe>/<rollenname>.yml`
* `<rollenname>.yml` (Playbook)

## Schritt 5: Echte Config vom Server holen

```bash
ansible immich -m fetch -a "src=/opt/immich/config.yml dest=/tmp/immich/ flat=no"
cat /tmp/immich/immich/opt/immich/config.yml
```

## Schritt 6: Secrets identifizieren

Beim Durchschauen der Config auf folgendes achten:

* Passwörter (`DB_PASSWORD`, `password:`, etc.)
* API-Keys / Tokens
* Sonstige geheime Strings

**Nicht als Secret behandeln:** interne IPs (192.168.178.x), Hostnamen, normale Settings wie Ports oder Pfade.

## Schritt 7: Secrets in Vaultwarden anlegen

Im Vaultwarden Web-UI (`vaultwarden.luebb.de`):

* Typ: Login
* Name: `<rollenname>-<beschreibung>` (z. B. `immich-db-password`)
* Password: der echte Wert aus der Config

Pro Secret ein eigener Eintrag, auch wenn mehrere Services das gleiche Passwort nutzen.

Nach dem Anlegen synchronisieren und prüfen:

```bash
bw sync
bw get password immich-db-password
```

## Schritt 8: host_vars befüllen

Datei: `host_vars/<inventory-gruppe>/<rollenname>.yml`

```yaml
immich_db_password: "{{ lookup('community.general.bitwarden', 'immich-db-password', field='password') | first }}"
```

Ein Eintrag pro Secret.

## Schritt 9: Template befüllen

Den kompletten Inhalt der echten Config aus Schritt 5 in
`roles/<rollenname>/templates/config.yml.j2` einfügen.

Dabei jeden Secret-Wert durch die passende Jinja2-Variable ersetzen:

```yaml
# vorher
DB_PASSWORD=geheimesPasswort123

# nachher
DB_PASSWORD={{ immich_db_password }}
```

## Schritt 10: Tasks anpassen

Falls nötig, in `roles/<rollenname>/tasks/main.yml` den Zielpfad der Config korrigieren (Standard ist `/opt/<rollenname>/config.yml`).

## Schritt 11: Testen (Dry-Run)

```bash
ansible-playbook <rollenname>.yml --check --diff
```

Der Diff sollte **nur** echte Unterschiede zeigen (z. B. neues Passwort), keine kompletten Config-Umstellungen.

## Schritt 12: Deployen

```bash
ansible-playbook <rollenname>.yml
```

## Schritt 13: Committen

```bash
git add .
git commit -m "Add <rollenname> role"
git push
```

## Schritt 14 (optional): In site.yml und README eintragen

* `site.yml`: einen neuen Play für die Role ergänzen
* `.github/scripts/generate_readme.py`: den Host im `SERVICE_INFO` Dictionary ergänzen, damit er automatisch in der README-Tabelle erscheint

## Checkliste zum Abhaken

- [ ] Service läuft und ist fertig konfiguriert
- [ ] Host im Inventory
- [ ] SSH-Key verteilt, `ansible <host> -m ping` erfolgreich
- [ ] Role-Grundgerüst per Script erzeugt
- [ ] Echte Config vom Server geholt
- [ ] Alle Secrets identifiziert
- [ ] Alle Secrets in Vaultwarden angelegt
- [ ] host_vars mit Lookups befüllt
- [ ] Template mit echter Config + Variablen befüllt
- [ ] `--check --diff` zeigt nur erwartete Änderungen
- [ ] Deployed
- [ ] Committed und gepusht
- [ ] In site.yml ergänzt
- [ ] In README-Generator ergänzt
