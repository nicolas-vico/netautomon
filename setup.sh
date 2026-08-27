#!/bin/bash
# =============================================================
#  NetAutoMon — Automated Installation Script
#  Network Automation & Monitoring Platform
#  Author: Nicolás Noé Vico Lobato · IES Pacífico · 2026
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
header() { echo -e "\n${CYAN}══════════════════════════════════════${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}══════════════════════════════════════${NC}\n"; }

# ── Check root ────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  error "Please run as root: sudo bash setup.sh"
fi

# ── Check Ubuntu 22.04 / 24.04 ────────────────────────────────
OS=$(lsb_release -rs 2>/dev/null || echo "unknown")
if [[ "$OS" != "22.04" && "$OS" != "24.04" ]]; then
  warn "This script is tested on Ubuntu 22.04 and 24.04. Detected: $OS"
fi

# ── Request a database password without storing it in the repository ─
if [ -z "${ZABBIX_DB_PASSWORD:-}" ]; then
  read -r -s -p "Enter a new Zabbix database password: " ZABBIX_DB_PASSWORD
  echo ""
fi

if [[ ! "$ZABBIX_DB_PASSWORD" =~ ^[A-Za-z0-9._@%+=-]{12,128}$ ]]; then
  error "Use 12-128 characters: letters, numbers, dot, underscore, @, %, +, = or -."
fi

echo ""
echo -e "${CYAN}"
echo "  _   _      _   _         _        __  __"
echo " | \ | | ___| |_/ \  _   _| |_ ___ |  \/  | ___  _ __"
echo " |  \| |/ _ \ __/ _ \| | | | __/ _ \| |\/| |/ _ \| '_ \\"
echo " | |\  |  __/ || (_) | |_| | || (_) | |  | | (_) | | | |"
echo " |_| \_|\___|\__\___/ \__,_|\__\___/|_|  |_|\___/|_| |_|"
echo -e "${NC}"
echo "  Network Automation & Monitoring Platform"
echo "  Author: Nicolás Noé Vico Lobato · IES Pacífico · 2026"
echo ""

# ── Step 1: System update ─────────────────────────────────────
header "Step 1 — System update"
apt update -qq && apt upgrade -y -qq
log "System updated"

# ── Step 2: Base dependencies ─────────────────────────────────
header "Step 2 — Base dependencies"
apt install -y -qq git python3 python3-pip ansible sshpass snmp snmp-mibs-downloader wget curl apt-transport-https software-properties-common
log "Base dependencies installed"

# ── Step 3: Python libraries ──────────────────────────────────
header "Step 3 — Python libraries"
pip3 install -r requirements.txt --break-system-packages -q
log "Python libraries installed: netmiko, paramiko, pyyaml"

# ── Step 4: Prometheus ────────────────────────────────────────
header "Step 4 — Prometheus"
apt install -y -qq prometheus
systemctl enable prometheus --quiet
systemctl start prometheus
log "Prometheus installed and running on port 9090"

# ── Step 5: Grafana ───────────────────────────────────────────
header "Step 5 — Grafana"
wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list > /dev/null
apt update -qq
apt install -y -qq grafana
systemctl enable grafana-server --quiet
systemctl start grafana-server
log "Grafana installed and running on port 3000"

# ── Step 6: Zabbix 7.0 ───────────────────────────────────────
header "Step 6 — Zabbix 7.0"
if [[ "$OS" == "22.04" ]]; then
  ZABBIX_PKG="zabbix-release_7.0-2+ubuntu22.04_all.deb"
else
  ZABBIX_PKG="zabbix-release_7.0-2+ubuntu24.04_all.deb"
fi
wget -q "https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/${ZABBIX_PKG}"
dpkg -i "$ZABBIX_PKG" > /dev/null
apt update -qq
apt install -y -qq zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent mysql-server
log "Zabbix 7.0 installed"

# ── Step 7: Zabbix DB setup ───────────────────────────────────
header "Step 7 — Zabbix database"
mysql -uroot -e "CREATE DATABASE IF NOT EXISTS zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;" 2>/dev/null
mysql -uroot -e "CREATE USER IF NOT EXISTS 'zabbix'@'localhost' IDENTIFIED WITH mysql_native_password BY '${ZABBIX_DB_PASSWORD}';" 2>/dev/null
mysql -uroot -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';" 2>/dev/null
mysql -uroot -e "SET GLOBAL log_bin_trust_function_creators = 1;" 2>/dev/null
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | MYSQL_PWD="$ZABBIX_DB_PASSWORD" mysql --default-character-set=utf8mb4 -uzabbix zabbix 2>/dev/null
mysql -uroot -e "SET GLOBAL log_bin_trust_function_creators = 0;" 2>/dev/null
sed -i "s|^# DBPassword=.*|DBPassword=${ZABBIX_DB_PASSWORD}|" /etc/zabbix/zabbix_server.conf
locale-gen en_US.UTF-8 > /dev/null
systemctl enable zabbix-server zabbix-agent apache2 --quiet
systemctl restart zabbix-server zabbix-agent apache2
log "Zabbix database configured for user zabbix"

# ── Step 8: Cacti ─────────────────────────────────────────────
header "Step 8 — Cacti"
DEBIAN_FRONTEND=noninteractive apt install -y -qq cacti cacti-spine
log "Cacti installed"

# ── Step 9: SSH known hosts ───────────────────────────────────
header "Step 9 — SSH configuration"
mkdir -p ~/.ssh
ssh-keyscan 127.0.0.1 >> ~/.ssh/known_hosts 2>/dev/null
log "SSH known_hosts configured"

# ── Done ──────────────────────────────────────────────────────
header "Installation complete!"
echo -e "  ${GREEN}Services running:${NC}"
echo -e "  • Prometheus  → http://$(hostname -I | awk '{print $1}'):9090"
echo -e "  • Grafana     → http://$(hostname -I | awk '{print $1}'):3000  (change the default login immediately)"
echo -e "  • Zabbix      → http://$(hostname -I | awk '{print $1}')/zabbix  (change the default login immediately)"
echo -e "  • Cacti       → http://$(hostname -I | awk '{print $1}')/cacti  (complete setup and set a unique password)"
echo ""
echo -e "  ${YELLOW}Next steps:${NC}"
echo -e "  1. Copy inventory/hosts.example.yml to inventory/hosts.yml and adapt the IPs"
echo -e "  2. Copy ansible/inventory/hosts.example.ini to ansible/inventory/hosts.ini"
echo -e "  3. Configure SSH keys or Ansible Vault; do not store passwords in inventories"
echo -e "  4. Run: python3 scripts/ping_check.py"
echo -e "  5. Import Grafana dashboard ID 1860 (Node Exporter Full)"
echo ""
