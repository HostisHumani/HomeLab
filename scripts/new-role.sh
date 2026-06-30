#!/bin/bash
# Usage: ./scripts/new-role.sh <role-name> <inventory-group>
# Example: ./scripts/new-role.sh immich immich

set -e

ROLE_NAME=$1
INVENTORY_GROUP=$2

if [ -z "$ROLE_NAME" ] || [ -z "$INVENTORY_GROUP" ]; then
  echo "Usage: ./scripts/new-role.sh <role-name> <inventory-group>"
  echo "Example: ./scripts/new-role.sh immich immich"
  exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Erstelle Role: $ROLE_NAME"

mkdir -p "$BASE_DIR/roles/$ROLE_NAME/tasks"
mkdir -p "$BASE_DIR/roles/$ROLE_NAME/templates"
mkdir -p "$BASE_DIR/roles/$ROLE_NAME/handlers"
mkdir -p "$BASE_DIR/host_vars/$INVENTORY_GROUP"

# tasks/main.yml
cat > "$BASE_DIR/roles/$ROLE_NAME/tasks/main.yml" << EOF
---
- name: Deploy $ROLE_NAME config
  ansible.builtin.template:
    src: config.yml.j2
    dest: /opt/$ROLE_NAME/config.yml
    owner: root
    group: root
    mode: '0644'
  notify: Restart $ROLE_NAME
EOF

# handlers/main.yml
cat > "$BASE_DIR/roles/$ROLE_NAME/handlers/main.yml" << EOF
---
- name: Restart $ROLE_NAME
  ansible.builtin.service:
    name: $ROLE_NAME
    state: restarted
EOF

# templates/config.yml.j2
cat > "$BASE_DIR/roles/$ROLE_NAME/templates/config.yml.j2" << EOF
# TODO: echte Config hier einfügen
# Variablen aus host_vars verwenden, z.B. {{ ${ROLE_NAME}_password }}
EOF

# host_vars
cat > "$BASE_DIR/host_vars/$INVENTORY_GROUP/$ROLE_NAME.yml" << EOF
${ROLE_NAME}_password: "{{ lookup('community.general.bitwarden', '$ROLE_NAME-password', field='password') | first }}"
EOF

# Playbook
cat > "$BASE_DIR/$ROLE_NAME.yml" << EOF
---
- name: $ROLE_NAME deployen
  hosts: $INVENTORY_GROUP
  roles:
    - $ROLE_NAME
EOF

echo ""
echo "Fertig! Erstellt wurden:"
echo "  - roles/$ROLE_NAME/tasks/main.yml"
echo "  - roles/$ROLE_NAME/handlers/main.yml"
echo "  - roles/$ROLE_NAME/templates/config.yml.j2"
echo "  - host_vars/$INVENTORY_GROUP/$ROLE_NAME.yml"
echo "  - $ROLE_NAME.yml"
echo ""
echo "Naechste Schritte:"
echo "  1. In Vaultwarden einen Eintrag '$ROLE_NAME-password' anlegen"
echo "  2. roles/$ROLE_NAME/templates/config.yml.j2 mit der echten Config fuellen"
echo "  3. Testen: ansible-playbook $ROLE_NAME.yml --check --diff"
echo "  4. Deployen: ansible-playbook $ROLE_NAME.yml"
echo "  5. Committen: git add . && git commit -m 'Add $ROLE_NAME role' && git push"
