#!/data/data/com.termux/files/usr/bin/bash

# ============================================================
#          PIXEL HOMELAB COMMANDER - Konfiguration
# ============================================================
# Reference copy of the Termux dashboard script used for quick
# operational access to the homelab from a mobile device.
# This is NOT managed via Ansible - it runs locally in Termux.
# Adjust IPs below to match your own environment.

IP_OMV="192.168.X.X"
IP_PVE="192.168.X.X"
IP_PBS="192.168.X.X"
IP_FRIGATE="192.168.X.X"

USER_OMV="root"
USER_PBS="root"

NOTES_FILE="$HOME/.lab_notes"

CONSOLES=(
    "vm:100|HomeAssi"
    "lxc:101|Frigate"
    "lxc:102|Paperless"
    "lxc:103|NPMplus"
    "lxc:104|Zabbix"
    "lxc:105|MQTT"
    "lxc:106|Zigbee2MQTT"
    "lxc:109|TechnitiumDNS"
    "lxc:110|ntfy"
)

SSH="ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new"

G='\033[0;32m'
B='\033[0;34m'
Y='\033[1;33m'
R='\033[0;31m'
C='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

declare -A LXC_STATUS
declare -A VM_STATUS

disk_color() {
    local raw="$1"
    local pct
    pct=$(echo "$raw" | grep -oE '[0-9]+%' | tr -d '%')
    [[ -z "$pct" ]] && echo "$raw" && return
    if   (( pct >= 90 )); then echo "${R}${raw}${NC}"
    elif (( pct >= 70 )); then echo "${Y}${raw}${NC}"
    else                       echo "${G}${raw}${NC}"
    fi
}

temp_color() {
    local raw="$1"
    local val
    val=$(echo "$raw" | tr -d '°C')
    [[ -z "$val" ]] && echo "$raw" && return
    if   (( val >= 80 )); then echo "${R}${raw}${NC}"
    elif (( val >= 65 )); then echo "${Y}${raw}${NC}"
    else                       echo "${G}${raw}${NC}"
    fi
}

load_color() {
    local raw="$1"
    local val
    val=$(echo "$raw" | tr -d '%')
    [[ -z "$val" ]] && echo "$raw" && return
    if   (( val >= 80 )); then echo "${R}${raw}${NC}"
    elif (( val >= 50 )); then echo "${Y}${raw}${NC}"
    else                       echo "${G}${raw}${NC}"
    fi
}

check_status() {
    local tmp
    tmp=$(mktemp -d)
    { ping -c 1 -W 1 "$IP_PVE" &>/dev/null && echo "${G}ONLINE${NC}" || echo "${R}OFFLINE${NC}"; } > "$tmp/pve" &
    { ping -c 1 -W 1 "$IP_OMV" &>/dev/null && echo "${G}ONLINE${NC}" || echo "${R}OFFLINE${NC}"; } > "$tmp/omv" &
    { ping -c 1 -W 1 "$IP_PBS" &>/dev/null && echo "${G}ONLINE${NC}" || echo "${R}OFFLINE${NC}"; } > "$tmp/pbs" &
    { $SSH "$USER_OMV@$IP_OMV" "df -h /dev/nvme0n1p2 | awk 'NR==2{print \$3\"/\"\$2\" (\"\$5\")\"}'"; } > "$tmp/nvme" &
    { $SSH "root@$IP_PVE" "cat /sys/class/thermal/thermal_zone0/temp | awk '{printf \"%.0f°C\", \$1/1000}'"; } > "$tmp/cputemp" &
    { $SSH "root@$IP_PVE" "top -bn1 | grep 'Cpu' | awk '{printf \"%.0f%%\", 100-\$8}'"; } > "$tmp/cpuload" &
    { $SSH "root@$IP_PVE" "free -h | awk '/^Mem:/{print \$3\"/\"\$2}'"; } > "$tmp/ram" &
    { $SSH "root@$IP_PVE" "pct list 2>/dev/null"; } > "$tmp/lxclist" &
    { $SSH "root@$IP_PVE" "qm list 2>/dev/null"; } > "$tmp/vmlist" &
    wait
    PVE_S=$(cat "$tmp/pve")
    OMV_S=$(cat "$tmp/omv")
    PBS_S=$(cat "$tmp/pbs")
    NVME_S=$(disk_color "$(cat "$tmp/nvme")")
    CPU_T=$(temp_color "$(cat "$tmp/cputemp")")
    CPU_L=$(load_color "$(cat "$tmp/cpuload")")
    RAM_S=$(cat "$tmp/ram")

    LXC_STATUS=()
    while IFS= read -r line; do
        local id status
        id=$(echo "$line" | awk '{print $1}')
        status=$(echo "$line" | awk '{print $2}')
        [[ "$id" =~ ^[0-9]+$ ]] && LXC_STATUS[$id]="$status"
    done < "$tmp/lxclist"

    VM_STATUS=()
    while IFS= read -r line; do
        local id status
        id=$(echo "$line" | awk '{print $1}')
        status=$(echo "$line" | awk '{print $3}')
        [[ "$id" =~ ^[0-9]+$ ]] && VM_STATUS[$id]="$status"
    done < "$tmp/vmlist"

    rm -rf "$tmp"
}

confirm() {
    echo -ne "${Y}⚠  ${1:-Sicher?} [j/N] > ${NC}"
    read -r ans
    [[ "$ans" == "j" || "$ans" == "J" ]]
}

check_ssh_key() {
    if [[ ! -f ~/.ssh/id_rsa && ! -f ~/.ssh/id_ed25519 && ! -f ~/.ssh/id_ecdsa ]]; then
        echo -e "${Y}⚠  Kein SSH-Key gefunden – Passwort-Login aktiv.${NC}"
        echo -e "   Tipp: ${C}ssh-keygen -t ed25519${NC}"
        sleep 3
    fi
}

show_consoles() {
    echo -e "\n${Y}Konsolen-Direktzugriff:${NC}"
    local count=0
    for entry in "${CONSOLES[@]}"; do
        local typ id name dot
        typ="${entry%%:*}"
        id="${entry%%|*}"; id="${id##*:}"
        name="${entry##*|}"

        if [[ "$typ" == "vm" ]]; then
            [[ "${VM_STATUS[$id]}" == "running" ]] && dot="${G}●${NC}" || dot="${R}●${NC}"
        else
            [[ "${LXC_STATUS[$id]}" == "running" ]] && dot="${G}●${NC}" || dot="${R}●${NC}"
        fi

        printf "  $dot ${C}%3s)${NC} %-16s" "$id" "$name"
        (( count++ ))
        (( count % 2 == 0 )) && echo ""
    done
    [[ $(( count % 2 )) -ne 0 ]] && echo ""
    echo -e "  ${G}●${NC} ${C}omv)${NC} OMV Konsole"
    echo -e "  ${G}●${NC} ${C}pve)${NC} PVE Konsole"
    echo -e "  ${G}●${NC} ${C}pbs)${NC} PBS Konsole"
}

open_ssh() {
    eval "$1"
}

connect_console() {
    local opt="$1"
    for entry in "${CONSOLES[@]}"; do
        local typ id name status cmd
        typ="${entry%%:*}"
        id="${entry%%|*}"; id="${id##*:}"
        name="${entry##*|}"

        if [[ "$opt" != "$id" ]]; then continue; fi

        if [[ "$typ" == "vm" ]]; then
            status="${VM_STATUS[$id]}"
            cmd="$SSH -t root@$IP_PVE 'qm terminal $id'"
        else
            status="${LXC_STATUS[$id]}"
            cmd="$SSH -t root@$IP_PVE 'pct enter $id'"
        fi

        clear
        echo -e "${B}${BOLD}── $name ($id) ──${NC}"

        if [[ "$status" == "running" ]]; then
            echo -e "  Status: ${G}● running${NC}\n"
            echo -e "  ${G}1)${NC} Verbinden"
            echo -e "  ${Y}2)${NC} Stoppen"
            echo -e "  ${C}3)${NC} Neustarten"
            echo -e "  ${R}q)${NC} Abbrechen"
            echo -ne "\n${G}Auswahl > ${NC}"
            read -r sub
            case $sub in
                1) open_ssh "$cmd" ;;
                2)
                    if confirm "$name stoppen?"; then
                        [[ "$typ" == "vm" ]] \
                            && $SSH "root@$IP_PVE" "qm stop $id" \
                            || $SSH "root@$IP_PVE" "pct stop $id"
                        termux-vibrate -d 200
                        termux-toast "$name gestoppt"
                    fi ;;
                3)
                    if confirm "$name neustarten?"; then
                        [[ "$typ" == "vm" ]] \
                            && $SSH "root@$IP_PVE" "qm reboot $id" \
                            || $SSH "root@$IP_PVE" "pct reboot $id"
                        termux-vibrate -d 200
                        termux-toast "$name wird neugestartet"
                    fi ;;
                q|*) ;;
            esac
        else
            echo -e "  Status: ${R}● stopped${NC}\n"
            echo -e "  ${G}1)${NC} Starten & Verbinden"
            echo -e "  ${C}2)${NC} Nur Starten"
            echo -e "  ${R}q)${NC} Abbrechen"
            echo -ne "\n${G}Auswahl > ${NC}"
            read -r sub
            case $sub in
                1)
                    echo -e "${Y}Starte $name...${NC}"
                    [[ "$typ" == "vm" ]] \
                        && $SSH "root@$IP_PVE" "qm start $id" \
                        || $SSH "root@$IP_PVE" "pct start $id"
                    sleep 2
                    open_ssh "$cmd" ;;
                2)
                    echo -e "${Y}Starte $name...${NC}"
                    [[ "$typ" == "vm" ]] \
                        && $SSH "root@$IP_PVE" "qm start $id" \
                        || $SSH "root@$IP_PVE" "pct start $id"
                    termux-vibrate -d 200
                    termux-toast "$name gestartet" ;;
                q|*) ;;
            esac
        fi
        return 0
    done
    return 1
}

# ============================================================
# START
# ============================================================
check_ssh_key

while true; do
    check_status
    clear

    echo -e "${B}${BOLD}"
    echo -e "╔══════════════════════════════════════════════════════╗"
    echo -e "║           🖥  PIXEL HOMELAB COMMANDER                ║"
    echo -e "╚══════════════════════════════════════════════════════╝${NC}"
    echo -e "  PVE: $PVE_S  │  PBS: $PBS_S  │  OMV: $OMV_S"
    echo -e "  ${C}NVMe:${NC} $NVME_S"
    echo -e "  ${C}Temp:${NC} $CPU_T  │  ${C}Last:${NC} $CPU_L  │  ${C}RAM:${NC} $RAM_S"
    echo -e "${B}──────────────────────────────────────────────────────${NC}"

    echo -e "\n${Y}System & Storage:${NC}"
    echo -e "  ${C}4)${NC} LXC Liste       ${C}7)${NC} PVE Status"
    echo -e "  ${C}5)${NC} Frigate Logs    ${C}8)${NC} OMV Stats"
    echo -e "  ${C}6)${NC} Frigate Status${NC}"
    echo -e "  ${C}b)${NC} Backup Status    ${C}r)${NC} Reboot Menü"
    echo -e "  ${C}u)${NC} Update-Check     ${C}p)${NC} Port-Übersicht  ${C}n)${NC} Notizen"

    show_consoles

    echo -e "${B}──────────────────────────────────────────────────────${NC}"
    echo -e "  ${R}q)${NC} Exit"
    echo -ne "\n${G}Auswahl > ${NC}"
    read -r opt

    case $opt in
        "") ;;
        4)
            echo -e "${B}LXC Übersicht:${NC}"
            $SSH "root@$IP_PVE" "pct list"
            echo -e "\n${G}[Fertig] - Enter drücken...${NC}"; read ;;
        5)
            echo -e "${B}Frigate Logs (Strg+C zum Beenden):${NC}"
            $SSH -t "root@$IP_FRIGATE" "docker logs --tail 50 -f frigate" ;;
        6)
            $SSH "root@$IP_FRIGATE" 'docker ps -f name=frigate --format "table {{.Names}}\t{{.Status}}"'
            echo -e "\n${G}Enter drücken...${NC}"; read ;;
        7)
            $SSH "root@$IP_PVE" "pvesh get /nodes/proxmox/status --output-format yaml"
            echo -e "\n${G}Enter drücken...${NC}"; read ;;
        8)
            open_ssh "$SSH -t $USER_OMV@$IP_OMV htop" ;;
        b)
            echo -e "${B}Letzte Backups (PBS):${NC}\n"
            $SSH "$USER_PBS@$IP_PBS" "proxmox-backup-manager task list --all --output-format json-pretty" | \
            python3 -c "
import json, sys
from datetime import datetime
tasks = json.load(sys.stdin)
relevant = [t for t in tasks if t.get('worker_type') in ('backup','syncjob','prune','verify','garbage_collection')]
for t in relevant[:10]:
    ts = datetime.fromtimestamp(t['starttime']).strftime('%d.%m %H:%M')
    wid = t.get('worker_id') or ''
    status = t.get('status','?')
    print(f\"  {ts}  {t['worker_type']:<22} {wid:<30} {status}\")
"
            echo -e "\n${G}[Fertig] - Enter drücken...${NC}"; read ;;
        u)
            echo -e "${B}Update-Check...${NC}\n"
            echo -ne "  ${C}PVE:${NC} "
            pve_upd=$($SSH "root@$IP_PVE" "apt list --upgradable 2>/dev/null | grep -v '^Listing' | wc -l")
            [[ "$pve_upd" -gt 0 ]] && echo -e "${Y}${pve_upd} Updates verfügbar${NC}" || echo -e "${G}Alles aktuell${NC}"
            echo -ne "  ${C}OMV:${NC} "
            omv_upd=$($SSH "$USER_OMV@$IP_OMV" "apt list --upgradable 2>/dev/null | grep -v '^Listing' | wc -l")
            [[ "$omv_upd" -gt 0 ]] && echo -e "${Y}${omv_upd} Updates verfügbar${NC}" || echo -e "${G}Alles aktuell${NC}"
            echo -e "\n${G}[Fertig] - Enter drücken...${NC}"; read ;;
        p)
            echo -e "${B}Offene Ports auf PVE:${NC}\n"
            $SSH "root@$IP_PVE" "ss -tlnp | awk 'NR>1{split(\$4,a,\":\"); printf \"  Port %-6s %s\n\", a[length(a)], \$6}' | sort -t' ' -k2 -n"
            echo -e "\n${G}[Fertig] - Enter drücken...${NC}"; read ;;
        n)
            while true; do
                clear
                echo -e "${B}${BOLD}"
                echo -e "╔══════════════════════════════════════════════════════╗"
                echo -e "║                  📝  NOTIZEN                        ║"
                echo -e "╚══════════════════════════════════════════════════════╝${NC}"
                if [[ -f "$NOTES_FILE" && -s "$NOTES_FILE" ]]; then
                    local i=1
                    while IFS= read -r line; do
                        echo -e "  ${C}${i})${NC} $line"
                        (( i++ ))
                    done < "$NOTES_FILE"
                else
                    echo -e "  ${Y}Keine Notizen vorhanden.${NC}"
                fi
                echo -e "${B}──────────────────────────────────────────────────────${NC}"
                echo -e "  ${G}a)${NC} Hinzufügen   ${R}d)${NC} Löschen   ${Y}q)${NC} Zurück"
                echo -ne "\n${G}Auswahl > ${NC}"
                read -r note_opt
                case $note_opt in
                    a)
                        echo -ne "${G}Notiz > ${NC}"
                        read -r new_note
                        [[ -n "$new_note" ]] && echo "$new_note" >> "$NOTES_FILE" \
                            && termux-toast "Notiz gespeichert" ;;
                    d)
                        echo -ne "${Y}Zeile # löschen > ${NC}"
                        read -r del_line
                        [[ "$del_line" =~ ^[0-9]+$ ]] && sed -i "${del_line}d" "$NOTES_FILE" \
                            && termux-toast "Notiz gelöscht" ;;
                    q) break ;;
                esac
            done ;;
        r)
            echo -e "\n${Y}Welchen Server neustarten?${NC}"
            echo -e "  ${C}1)${NC} PVE Node"
            echo -e "  ${C}2)${NC} OMV"
            echo -e "  ${C}3)${NC} PBS"
            echo -ne "${G}Auswahl > ${NC}"
            read -r reboot_opt
            case $reboot_opt in
                1) confirm "PVE neustarten?" && $SSH "root@$IP_PVE" "reboot" \
                        && termux-toast "PVE Reboot ausgelöst" ;;
                2) confirm "OMV neustarten?" && $SSH "$USER_OMV@$IP_OMV" "reboot" \
                        && termux-toast "OMV Reboot ausgelöst" ;;
                3) confirm "PBS neustarten?" && $SSH "$USER_PBS@$IP_PBS" "reboot" \
                        && termux-toast "PBS Reboot ausgelöst" ;;
                *) echo -e "${R}Abgebrochen${NC}"; sleep 1 ;;
            esac ;;
        omv) open_ssh "$SSH -t $USER_OMV@$IP_OMV" ;;
        pve) open_ssh "$SSH -t root@$IP_PVE" ;;
        pbs) open_ssh "$SSH -t $USER_PBS@$IP_PBS" ;;
        q)
            termux-vibrate -d 50
            clear; exit ;;
        *)
            if ! connect_console "$opt"; then
                termux-vibrate -d 50 -f
                echo -e "${R}Ungültige Auswahl: '$opt'${NC}"
                sleep 1
            fi ;;
    esac
done
