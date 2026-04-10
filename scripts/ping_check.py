import yaml
import subprocess


def ping(ip):
    result = subprocess.run(
        ["ping", "-c", "1", "-W", "1", ip],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    return result.returncode == 0


def main():
    with open("inventory/hosts.yml") as f:
        data = yaml.safe_load(f)

    print(f"\n{'Dispositivo':<25} {'IP':<18} {'Estado'}")
    print("-" * 55)

    for device in data["devices"]:
        status = "✓ UP  " if ping(device["ip"]) else "✗ DOWN"
        print(f"{device['name']:<25} {device['ip']:<18} {status}")

    print()


if __name__ == "__main__":
    main()
