# NetAutoMon — Network Automation & Monitoring Platform

![Platform](https://img.shields.io/badge/Platform-Ubuntu%2022.04-orange?style=flat-square)
![Python](https://img.shields.io/badge/Python-3.10-blue?style=flat-square&logo=python)
![Ansible](https://img.shields.io/badge/Ansible-2.10-red?style=flat-square&logo=ansible)
![Zabbix](https://img.shields.io/badge/Zabbix-7.0-CC0000?style=flat-square)
![Grafana]![alt text](image.png)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

> **Final Year Project** · Higher Degree in Telecommunications and Computer Systems
> IES Pacífico · Madrid · 2026
> Author: **Nicolás Noé Vico Lobato**

---

## 📋 Overview

**NetAutoMon** is a NetDevOps platform that automates the management and monitoring of a real convergent network infrastructure providing IP telephony (VoIP), IP video surveillance (CCTV) and wireless connectivity (WiFi) services.

The platform runs on an Ubuntu Server 22.04 LTS virtual machine and is structured into three functional blocks:

| Block | Tools | Purpose |
|-------|-------|---------|
| **Automation** | Python · Netmiko · Ansible · Git | Device inventory, SSH config backups, config management |
| **Monitoring** | Zabbix 7.0 · Cacti · Prometheus | SNMP monitoring, traffic graphs, metrics collection |
| **Visualization** | Grafana · Telegram Bot API | Real-time dashboards, automated alerting |

---

## 🏗️ Architecture

```
Network (172.16.90.0/24)
│
├── UDM-SE          172.16.90.1   Router · Switch · Firewall · WiFi · CCTV · VPN
├── UAP-AC-1        172.16.90.2   WiFi Access Point
├── UAP-AC-2        172.16.90.3   WiFi Access Point
├── Proxmox         172.16.90.50  Hypervisor
├── VM Asterisk     172.16.90.51  VoIP PBX
├── VM Asterisk     172.16.90.52  VoIP PBX
├── VM Pi-Hole      172.16.90.53  DNS / AdBlock
└── VM NetAutoMon   172.16.90.54  ← This platform
         │
         ├── Python (Netmiko)   → Inventory + SSH Backups
         ├── Ansible            → Configuration Management
         ├── Zabbix 7.0         → SNMP Monitoring
         ├── Cacti              → Traffic Graphs
         ├── Prometheus         → Metrics Collection
         ├── Grafana            → Dashboards + Alerts
         └── Telegram Bot       → Automated Notifications
```

---

## 📁 Repository Structure

```
netautomon/
├── inventory/
│   └── hosts.yml              # Device inventory (no credentials)
├── scripts/
│   ├── ping_check.py          # Connectivity check for all devices
│   └── backup_config.py       # Automated SSH configuration backup
├── ansible/
│   ├── inventory/
│   │   └── hosts.ini          # Ansible inventory (no credentials)
│   └── playbooks/
│       ├── info_sistema.yml   # Gather uptime, disk and memory info
│       ├── info_red.yml       # Gather interfaces, routes and connections
│       └── actualizar_sistema.yml  # Automated system update
├── backups/                   # Generated backups (excluded from Git)
├── docs/                      # Additional documentation
├── .gitignore
├── LICENSE
└── README.md
```

---

## ⚙️ Requirements

### Infrastructure
- Ubuntu Server 22.04 LTS VM (minimum 1GB RAM, 20GB disk)
- Network access to monitored devices
- Devices with SNMP v2c enabled

### Software
- Python 3.10+
- Ansible 2.10+
- Prometheus 2.x
- Grafana 10.x
- Zabbix 7.0
- Cacti 1.2

---

## 🚀 Installation

### 1. Clone the repository

```bash
git clone https://github.com/nicolas-vico/netautomon.git
cd netautomon
```

### 2. Install Python dependencies

```bash
pip3 install netmiko paramiko pyyaml --break-system-packages
```

### 3. Configure the inventory

Edit `inventory/hosts.yml` with your device IPs and credentials:

```yaml
devices:
  - name: My-Router
    ip: 192.168.1.1
    type: linux
    username: admin
    password: your_password
    services: [router]
```

> ⚠️ **Never commit credentials to GitHub.** The `hosts.yml` file is listed in `.gitignore`.

### 4. Configure Ansible

Edit `ansible/inventory/hosts.ini`:

```ini
[linux]
My-Server ansible_host=192.168.1.10 ansible_user=root

[linux:vars]
ansible_ssh_pass=your_password
```

### 5. Install Zabbix 7.0

```bash
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu24.04_all.deb
dpkg -i zabbix-release_7.0-2+ubuntu24.04_all.deb
apt update
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent mysql-server
```

### 6. Install Prometheus and Grafana

```bash
apt install -y prometheus
wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
apt update && apt install -y grafana
systemctl enable --now grafana-server
```

### 7. Install Cacti

```bash
apt install -y cacti cacti-spine
```

---

## 📖 Usage

### Python — Connectivity check

```bash
python3 scripts/ping_check.py
```

Expected output:
```
Device                    IP                 Status
-------------------------------------------------------
UDM-SE                    172.16.90.1        ✓ UP
UAP-AC-1                  172.16.90.2        ✓ UP
UAP-AC-2                  172.16.90.3        ✓ UP
Proxmox                   172.16.90.50       ✓ UP
VM-NetAutoMon             172.16.90.54       ✓ UP
```

### Python — Configuration backup

```bash
python3 scripts/backup_config.py
```

Backups are saved in `backups/` with the format `HOSTNAME_YYYY-MM-DD.txt`.

### Ansible — System information

```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/info_sistema.yml
```

### Ansible — System update

```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/actualizar_sistema.yml
```

### Check monitoring services

```bash
systemctl status zabbix-server prometheus grafana-server --no-pager
```

---

## 📊 Web interfaces

| Service | URL | Default credentials |
|---------|-----|---------------------|
| Zabbix | `http://YOUR-IP/zabbix` | Admin / zabbix |
| Grafana | `http://YOUR-IP:3000` | admin / admin |
| Cacti | `http://YOUR-IP/cacti` | admin / admin |
| Prometheus | `http://YOUR-IP:9090` | — |

> ⚠️ Change default passwords on first login.

---

## 🔔 Telegram Alerts

1. Create a bot with [@BotFather](https://t.me/botfather) on Telegram
2. Get your `Chat ID` by visiting `https://api.telegram.org/botYOUR_TOKEN/getUpdates`
3. In Grafana: **Alerting → Contact points → Add → Telegram**
4. Set your bot token and Chat ID
5. Create alert rules in **Alerting → Alert rules**

Example alert configured: **High RAM** — triggers when memory usage exceeds 85%.

---

## 🛠️ Tech Stack

| Tool | Version | Purpose |
|------|---------|---------|
| Ubuntu Server | 22.04 LTS | Base OS |
| Python | 3.10 | Automation scripts |
| Netmiko | 4.6 | SSH device connections |
| Ansible | 2.10 | Configuration management |
| Prometheus | 2.x | Metrics collection |
| Grafana | 10.x | Dashboards and alerting |
| Zabbix | 7.0 | SNMP monitoring |
| Cacti | 1.2 | Traffic graphs |
| Git / GitHub | — | Version control (GitOps) |
| Telegram Bot API | — | Automated notifications |

---

## 📚 References

- [Zabbix 7.0 Documentation](https://www.zabbix.com/documentation/7.0/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Netmiko on GitHub](https://github.com/ktbyers/netmiko)

---

## 👤 Author

**Nicolás Noé Vico Lobato**
Junior Network & Cloud Engineer | CCNA · Fortinet · NetDevOps
📧 nicovicolobato@gmail.com
🔗 [LinkedIn](https://linkedin.com/in/nicolas-vico) · [GitHub](https://github.com/nicolas-vico)
📍 Relocating to Zürich, Switzerland — June 2026

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.