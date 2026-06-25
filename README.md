# HomeLab
Proxmox on: MacMini 2018 6 x Intel(R) Core(TM) i5-8500B CPU @ 3.00GHz (1 Socket) 16 GB RAM 

OpenMediaVault on: Pi5 8 GB RAM

Proxmox Backup Server on: HP 255 G5 4 x AMD A6-7310 APU with AMD Radeon R4 Graphics 8 GB RAM

## Zigbee2MQTT Geräte-Management

Neue Geräte werden über die Zigbee2MQTT Web UI hinzugefügt.
Nach dem Hinzufügen die configuration.yaml ins Repo übernehmen:

```bash
ansible zigbee2mqtt -m fetch -a "src=/opt/zigbee2mqtt/data/configuration.yaml dest=roles/zigbee2mqtt/templates/configuration.yaml flat=yes"
git add . && git commit -m "zigbee2mqtt: add device XYZ" && git push
```
