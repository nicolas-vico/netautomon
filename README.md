# NetAutoMon 🌐
### Network Automation & Monitoring Platform

![Python](https://img.shields.io/badge/Python-3.10+-blue?logo=python)
![Ansible](https://img.shields.io/badge/Ansible-2.14+-red?logo=ansible)
![Prometheus](https://img.shields.io/badge/Prometheus-2.40+-orange?logo=prometheus)
![Grafana](https://img.shields.io/badge/Grafana-9.0+-yellow?logo=grafana)
![License](https://img.shields.io/badge/License-MIT-green)

Plataforma NetDevOps para automatización y monitorización de redes convergentes (ToIP, CCTV, WiFi). Proyecto de Fin de Curso — Grado Superior de Sistemas de Telecomunicaciones e Informáticos.

## 🏗️ Arquitectura
```
Red de servicios (ToIP · CCTV · WiFi)
        ↓  SSH / SNMP
  VM Ubuntu Server 22.04 (Proxmox)
  ├── Python + Netmiko   → Inventario y backups
  ├── Ansible            → Gestión de configuraciones
  ├── Prometheus+Grafana → Monitorización moderna
  └── Zabbix + Cacti     → Monitorización empresarial
```

## 📦 Estructura del proyecto

| Carpeta | Contenido |
|---|---|
| `inventory/` | Inventario de dispositivos en YAML |
| `ansible/` | Playbooks de configuración |
| `scripts/` | Scripts Python (inventario, backups) |
| `monitoring/` | Configuración Prometheus, Grafana, Zabbix, Cacti |
| `docs/` | Documentación y capturas |

## 🚀 Progreso

- [x] Estructura del repositorio
- [ ] Inventario dinámico con Python
- [ ] Backups automáticos de configuraciones
- [ ] Playbooks Ansible
- [ ] Stack Prometheus + Grafana
- [ ] Zabbix + Cacti

## 🛠️ Stack tecnológico
Python · Netmiko · Ansible · Prometheus · Grafana · Zabbix · Cacti · Git

## 👤 Autor
**Nicolas Noe Vico Lobato** — Grado Superior STI · IES Pacífico