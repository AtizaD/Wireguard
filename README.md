# WireGuard VPN Auto-Setup Script 🔒

An automated WireGuard VPN setup script for Debian/Ubuntu servers with easy installation, management, and client configuration.

## 🚀 Quick Install

Run this command on your server:

```bash
curl -O https://raw.githubusercontent.com/AtizaD/wireguard/main/setup.sh && chmod +x setup.sh && sudo ./setup.sh -i
```

## ✨ Features

- 🔧 One-command installation
- 🔄 Auto-detection of network interface
- 🖥️ Platform compatibility checking
- 📱 QR code generation for mobile clients
- 🔍 Configuration status viewer
- 🗑️ Clean uninstallation option
- 📝 Installation logging
- 🛡️ UFW firewall configuration
- 🔌 Automatic service management

## 🛠️ Requirements

- Ubuntu or Debian based system
- Root privileges
- Active internet connection

## 📋 Usage

```bash
# Install WireGuard
sudo ./setup.sh -i

# Show current configuration
sudo ./setup.sh -s

# Uninstall WireGuard
sudo ./setup.sh -u
```

## ⚙️ Configuration Details

- Default interface: wg0
- Default port: 3333 (UDP)
- Default network: 10.24.10.0/24
- Server IP: 10.24.10.1
- Client IP: 10.24.10.12
- Log file: /var/log/wireguard-setup.log

## 📱 Client Setup

After installation:
1. Server displays QR code for mobile clients
2. Client config saved at: `/etc/wireguard/client.conf`
3. Use WireGuard app to scan QR code or import config file

## 🔒 Security Features

- Automatic key generation
- UFW firewall configuration
- IP forwarding setup
- NAT masquerading
- Strict peer configuration

## 🚨 Troubleshooting

Check the log file for installation details:
```bash
cat /var/log/wireguard-setup.log
```

View WireGuard status:
```bash
sudo ./setup.sh -s
```

## ⚠️ Important Notes

- Run script with root privileges
- Backup any existing WireGuard configurations before installing
- Default port (3333) can be changed in the script if needed
- Script supports only Debian/Ubuntu systems

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check [issues page](https://github.com/AtizaD/wireguard/issues).

## 🙏 Acknowledgments

- WireGuard Project
- Community contributors

---
Remember to star ⭐ this repository if you find it helpful!
