
## Notfall-Zugang (Backup SSH-Key)

Falls die SmartCard verloren geht, beschädigt wird, oder das AdminBook selbst
ausfällt, gibt es einen zusätzlichen, unabhängigen SSH-Key als Fallback.

**Wichtig:** Die privaten GPG-Schlüssel existieren NUR auf der SmartCard
(siehe `sec>`/`ssb>` Markierung bei `gpg --list-secret-keys`). Es gibt kein
Backup der privaten Schlüssel. Geht die Karte verloren, sind diese
unwiederbringlich weg - SSH-Zugriff läuft dann ausschließlich über den
Emergency-Key, bis neue Schlüssel/eine neue Karte eingerichtet sind.

### Key-Erstellung

```bash
ssh-keygen -t ed25519 -f ~/.ssh/emergency_key -C "AdminBook Emergency Backup Key"
```

Mit Passphrase geschützt. Private Key und Passphrase sind in Vaultwarden
gesichert (`adminbook-emergency-ssh-key`).

### Verteilung auf alle Hosts

```bash
KEY=$(cat ~/.ssh/emergency_key.pub)
for ip in <alle-server-ips>; do
  ssh root@$ip "mkdir -p /root/.ssh && echo '$KEY' >> /root/.ssh/authorized_keys"
done
```

### Nutzung im Notfall

```bash
ssh -i ~/.ssh/emergency_key root@<IP>
```

Bei Verlust des AdminBooks selbst: privaten Key aus Vaultwarden-Backup
wiederherstellen, lokal als `~/.ssh/emergency_key` ablegen, `chmod 600` setzen.
