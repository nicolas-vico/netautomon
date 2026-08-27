import yaml
import os
from datetime import datetime
from netmiko import ConnectHandler

BACKUP_DIR = "backups"


def connection_options(device):
    if "password" in device:
        raise ValueError(
            "Passwords in inventory files are not supported. "
            "Use an SSH key or NETAUTOMON_SSH_PASSWORD."
        )

    username = device.get("username") or os.getenv("NETAUTOMON_SSH_USERNAME")
    if not username:
        raise ValueError(
            f"No SSH username configured for {device['name']}. "
            "Set it in the local inventory or NETAUTOMON_SSH_USERNAME."
        )

    options = {
        "device_type": "linux",
        "host": device["ip"],
        "username": username,
    }

    password = os.getenv("NETAUTOMON_SSH_PASSWORD")
    key_file = os.getenv("NETAUTOMON_SSH_KEY_FILE")

    if password:
        options["password"] = password
    else:
        options["use_keys"] = True
        options["allow_agent"] = True
        if key_file:
            options["key_file"] = os.path.expanduser(key_file)

    return options


def backup_linux(device):
    connection = ConnectHandler(**connection_options(device))

    commands = [
        "ip addr show",
        "ip route show",
        "cat /etc/hosts",
    ]

    try:
        output = f"# Backup {device['name']} - {datetime.now()}\n\n"
        for cmd in commands:
            result = connection.send_command(cmd)
            output += f"## {cmd}\n{result}\n\n"
        return output
    finally:
        connection.disconnect()


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
        if device["type"] == "linux":
            print(f"Conectando a {device['name']} ({device['ip']})...")
            try:
                content = backup_linux(device)
                save_backup(device["name"], content)
            except Exception as e:
                print(f"✗ Error en {device['name']}: {e}")


if __name__ == "__main__":
    main()
