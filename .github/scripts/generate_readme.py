#!/usr/bin/env python3
"""Generate the Services table in README.md from inventory/hosts.yml.example"""

import re
import yaml

INVENTORY_FILE = "inventory/hosts.yml.example"
README_FILE = "README.md"
START_MARKER = "<!-- AUTO-GENERATED-START -->"
END_MARKER = "<!-- AUTO-GENERATED-END -->"

# Host -> (Service Name, Platform, Purpose)
SERVICE_INFO = {
    "pve": ("Proxmox VE", "Bare Metal", "Hypervisor"),
    "pbs-node": ("Proxmox Backup Server", "Bare Metal", "Backup Server"),
    "technitiumdns": ("Technitium DNS", "Debian LXC", "Primary DNS Server (includes Keepalived for HA)"),
    "npmplus": ("NPMplus", "Alpine LXC + Docker", "Reverse Proxy"),
    "frigate": ("Frigate", "Debian LXC + Docker", "Network Video Recorder"),
    "paperless": ("Paperless-ngx", "Debian LXC", "Document Management"),
    "mqtt": ("Mosquitto", "Debian LXC", "MQTT Broker"),
    "zigbee2mqtt": ("Zigbee2MQTT", "Debian LXC", "Zigbee Gateway"),
    "ntfy": ("ntfy", "Debian LXC", "Push Notifications"),
    "zabbix": ("Zabbix", "Debian LXC", "Monitoring"),
    "piNAS": ("OpenMediaVault", "Raspberry Pi 5", "NAS Host (base system only)"),
    "AdminBook": ("AdminBook", "ThinkPad T480", "Ansible Control Node (admin workstation)"),
}

# Preferred display order
HOST_ORDER = [
    "pve", "pbs-node", "technitiumdns", "npmplus", "frigate",
    "paperless", "mqtt", "zigbee2mqtt", "ntfy", "zabbix", "piNAS",
    "AdminBook",
]


def load_hosts(inventory_path):
    with open(inventory_path, "r") as f:
        data = yaml.safe_load(f)

    hosts = set()

    def walk(node):
        if not isinstance(node, dict):
            return
        if "hosts" in node and isinstance(node["hosts"], dict):
            hosts.update(node["hosts"].keys())
        for value in node.values():
            if isinstance(value, dict):
                walk(value)

    walk(data)
    return hosts


def build_table(hosts):
    rows = []
    for host in HOST_ORDER:
        if host not in hosts:
            continue
        if host not in SERVICE_INFO:
            continue
        name, platform, purpose = SERVICE_INFO[host]
        rows.append((name, platform, "Ansible", purpose))

    # Any host present in inventory but missing from SERVICE_INFO/HOST_ORDER
    for host in sorted(hosts - set(HOST_ORDER)):
        rows.append((host, "Unknown", "Ansible", "No description available"))

    header = "| Service | Platform | Management | Purpose |\n"
    header += "| ------- | -------- | ---------- | ------- |\n"
    body = "\n".join(
        f"| {name} | {platform} | {management} | {purpose} |"
        for name, platform, management, purpose in rows
    )
    return header + body + "\n"


def update_readme(table):
    with open(README_FILE, "r") as f:
        content = f.read()

    pattern = re.compile(
        re.escape(START_MARKER) + r".*?" + re.escape(END_MARKER),
        re.DOTALL,
    )

    replacement = (
        f"{START_MARKER}\n"
        f"<!-- This table is automatically generated from {INVENTORY_FILE} - do not edit manually -->\n\n"
        f"{table}\n"
        f"{END_MARKER}"
    )

    new_content = pattern.sub(replacement, content)

    with open(README_FILE, "w") as f:
        f.write(new_content)


def main():
    hosts = load_hosts(INVENTORY_FILE)
    table = build_table(hosts)
    update_readme(table)
    print(f"README.md updated with {len(hosts)} hosts found in inventory.")


if __name__ == "__main__":
    main()
