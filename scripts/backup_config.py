import yaml
import os
from datetime import datetime
from netmiko import ConnectHandler

BACKUP_DIR = "backups"


def backup_linux(device):
    connection = ConnectHandler(
        device_type="linux",
        host=device["ip"],
        username=device["username"],
        password=device["password"],
    )

    commands = [
        "ip addr show",
        "ip route show",
        "cat /etc/hosts",
    ]

    output = f"# Backup {device['name']} - {datetime.now()}\n\n"
    for cmd in commands:
        result = connection.send_command(cmd)
        output += f"## {cmd}\n{result}\n\n"

    connection.disconnect()
    return output


def save_backup(name, content):
    date = datetime.now().strftime("%Y-%m-%d")
    filename = f"{BACKUP_DIR}/{name}_{date}.txt"
    with open(filename, "w") as f:
        f.write(content)
    print(f"✓ Backup guardado: {filename}")


def main():
    with open("inventory/hosts.yml") as f:
        data = yaml.safe_load(f)

    for device in data["devices"]:
        if device["type"] == "linux" and "username" in device:
            print(f"Conectando a {device['name']} ({device['ip']})...")
            try:
                content = backup_linux(device)
                save_backup(device["name"], content)
            except Exception as e:
                print(f"✗ Error en {device['name']}: {e}")


if __name__ == "__main__":
    main()
