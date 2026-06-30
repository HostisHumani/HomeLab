# My HomeLab

Infrastructure as Code for my personal homelab.

The goal of this project is to build a reproducible, version-controlled and well documented homelab using Ansible as the primary automation tool.

## Features

* Infrastructure as Code with Ansible
* Idempotent deployments
* Secrets managed with Bitwarden CLI
* Git-based configuration management
* High Availability with Keepalived
* Docker and bare-metal deployments
* Proxmox VE & Proxmox Backup Server support
* Zabbix monitoring

## Infrastructure

| Host                  | Hardware                                        | Role                |
| --------------------- | ----------------------------------------------- | ------------------- |
| Proxmox VE            | Mac mini 2018 • Intel Core i5-8500B • 16 GB RAM | Virtualization Host |
| OpenMediaVault        | Raspberry Pi 5 • 8 GB RAM                       | NAS & Docker Host   |
| Proxmox Backup Server | HP 255 G5 • AMD A6-7310 • 8 GB RAM              | Backup Server       |

## Services managed by Ansible

<!-- AUTO-GENERATED-START -->
<!-- This table is automatically generated from inventory/hosts.yml.example - do not edit manually -->

| Service | Platform | Management | Purpose |
| ------- | -------- | ---------- | ------- |
| Proxmox VE | Bare Metal | Ansible | Hypervisor |
| Proxmox Backup Server | Bare Metal | Ansible | Backup Server |
| Technitium DNS | Debian LXC | Ansible | Primary DNS Server (includes Keepalived for HA) |
| NPMplus | Alpine LXC + Docker | Ansible | Reverse Proxy |
| Frigate | Debian LXC + Docker | Ansible | Network Video Recorder |
| Paperless-ngx | Debian LXC | Ansible | Document Management |
| Mosquitto | Debian LXC | Ansible | MQTT Broker |
| Zigbee2MQTT | Debian LXC | Ansible | Zigbee Gateway |
| ntfy | Debian LXC | Ansible | Push Notifications |
| Zabbix | Debian LXC | Ansible | Monitoring |
| OpenMediaVault | Raspberry Pi 5 | Ansible | NAS Host (base system only) |

<!-- AUTO-GENERATED-END -->

## Services managed outside of Ansible

| Service                     | Platform              | Management      | Purpose                                           |
| ---------------------------- | --------------------- | ---------------- | -------------------------------------------------- |
| Home Assistant               | Home Assistant OS     | Appliance        | Home Automation                                    |
| OpenMediaVault                | Raspberry Pi 5        | Appliance        | NAS & Docker Host                                  |
| Chrony                        | OMV + Docker Compose  | Docker Compose   | Local NTP Server                                   |
| Fritz!Box Zabbix Monitoring   | OMV + Docker Compose  | Docker Compose   | FRITZ!Box Monitoring                               |
| Jotty                         | OMV + Docker Compose  | Docker Compose   | Notes Application                                  |
| Linkwarden                    | OMV + Docker Compose  | Docker Compose   | Bookmark Manager                                   |
| Radicale                      | OMV + Docker Compose  | Docker Compose   | CalDAV/CardDAV Server                              |
| Technitium DNS (Fallback)     | OMV + Docker Compose  | Docker Compose   | Secondary DNS Server (includes Keepalived for HA)  |

## Scope

This repository serves as the single source of truth for my homelab infrastructure.

It contains the Ansible roles, inventories, variables and configuration required to deploy and maintain the managed systems.

Not every component is managed by Ansible. Some systems intentionally remain outside of Ansible because they are distributed as dedicated appliances or use their own management interface.

### Managed by Ansible

* Host configuration
* System updates
* Service configuration
* Docker-based applications
* Monitoring
* High Availability
* Infrastructure provisioning

### Managed outside of Ansible

* Home Assistant OS
* OpenMediaVault
* Docker Compose stacks running on OpenMediaVault

## Roadmap

* [x] GitHub Actions
* [ ] Dell PowerEdge T440 migration
* [ ] OPNsense firewall
* [ ] Immich
* [ ] Extended documentation

## Getting Started

Clone the repository:

```bash
git clone https://github.com/HostisHumani/HomeLab.git
cd HomeLab
```

Create your global configuration:

```bash
cp group_vars/all.yml.example group_vars/all.yml
```

Adjust the inventory and Bitwarden items to match your environment.

Run the deployment:

```bash
ansible-playbook site.yml
```

## License

MIT
