#!/bin/bash
# WireGuard Management Script (Enhanced)
# Features: Install, Uninstall, Show Config, Auto-Detection

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WG_IFACE="wg0"
WG_PORT="3333"
WG_NETWORK="10.24.10.0/24"
WG_SERVER_IP="10.24.10.1"
CLIENT_IP="10.24.10.12"
CLIENT_NAME="client"
WG_DIR="/etc/wireguard"
LOG_FILE="/var/log/wireguard-setup.log"

# Function to check root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: Please run as root${NC}"
        exit 1
    fi
}

# Function to check platform compatibility
check_platform() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case $ID in
            ubuntu|debian)
                echo -e "${GREEN}✓ Platform supported: $ID${NC}"
                ;;
            *)
                echo -e "${RED}Error: Unsupported platform: $ID${NC}"
                exit 1
                ;;
        esac
    else
        echo -e "${RED}Error: Cannot determine OS${NC}"
        exit 1
    fi
}

# Function to check if WireGuard is installed
check_wireguard() {
    command -v wg >/dev/null 2>&1
}

# Function to show existing configurations
show_config() {
    echo -e "${BLUE}WireGuard Status:${NC}"
    if check_wireguard; then
        echo -e "${GREEN}WireGuard is installed${NC}"
        if [ -d "$WG_DIR" ]; then
            echo -e "\n${BLUE}Available Configurations:${NC}"
            ls -l $WG_DIR/*.conf 2>/dev/null
            echo -e "\n${BLUE}Active Interfaces:${NC}"
            wg show all
        else
            echo "No configurations found in $WG_DIR"
        fi
    else
        echo -e "${RED}WireGuard is not installed${NC}"
    fi
}

# Function to uninstall WireGuard
uninstall_wireguard() {
    if check_wireguard; then
        echo -e "${BLUE}Uninstalling WireGuard...${NC}"
        systemctl stop wg-quick@$WG_IFACE
        systemctl disable wg-quick@$WG_IFACE
        apt remove -y wireguard wireguard-tools qrencode
        rm -rf $WG_DIR
        ufw delete allow $WG_PORT/udp
        sed -i '/net.ipv4.ip_forward=1/d' /etc/sysctl.conf
        sysctl -p
        echo -e "${GREEN}WireGuard has been uninstalled${NC}"
    else
        echo -e "${RED}WireGuard is not installed${NC}"
    fi
}

# Function to install WireGuard
install_wireguard() {
    if check_wireguard; then
        echo -e "${RED}WireGuard is already installed${NC}"
        echo "Use -s to show current configuration or -u to uninstall first"
        exit 1
    fi

    echo -e "${BLUE}🔹 Installing WireGuard & UFW...${NC}"
    apt update && apt install -y wireguard qrencode ufw | tee -a $LOG_FILE

    echo -e "${BLUE}🔹 Generating WireGuard Server Keys...${NC}"
    mkdir -p $WG_DIR
    cd $WG_DIR
    wg genkey | tee privatekey | wg pubkey > publickey
    SERVER_PRIVATE_KEY=$(cat privatekey)
    SERVER_PUBLIC_KEY=$(cat publickey)

    echo -e "${BLUE}🔹 Generating Client Keys...${NC}"
    wg genkey | tee ${CLIENT_NAME}_privatekey | wg pubkey > ${CLIENT_NAME}_publickey
    CLIENT_PRIVATE_KEY=$(cat ${CLIENT_NAME}_privatekey)
    CLIENT_PUBLIC_KEY=$(cat ${CLIENT_NAME}_publickey)

    DEFAULT_INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')

    echo -e "${BLUE}🔹 Creating WireGuard Server Configuration...${NC}"
    cat > $WG_DIR/$WG_IFACE.conf <<EOF
[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = $WG_SERVER_IP/24
ListenPort = $WG_PORT
SaveConfig = false
PostUp = iptables -A FORWARD -i $WG_IFACE -j ACCEPT; iptables -t nat -A POSTROUTING -o $DEFAULT_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i $WG_IFACE -j ACCEPT; iptables -t nat -D POSTROUTING -o $DEFAULT_INTERFACE -j MASQUERADE

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $CLIENT_IP/32
EOF

    echo -e "${BLUE}🔹 Enabling IP Forwarding...${NC}"
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p

    echo -e "${BLUE}🔹 Configuring Firewall (UFW)...${NC}"
    ufw allow $WG_PORT/udp
    ufw allow OpenSSH
    ufw --force enable

    echo -e "${BLUE}🔹 Starting WireGuard VPN...${NC}"
    systemctl enable wg-quick@$WG_IFACE
    systemctl start wg-quick@$WG_IFACE

    echo -e "${BLUE}🔹 Creating Client Configuration...${NC}"
    cat > $WG_DIR/${CLIENT_NAME}.conf <<EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP/24
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $(curl -s ifconfig.me):$WG_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

    echo -e "${GREEN}✅ WireGuard Setup Complete!${NC}"
    echo -e "${GREEN}📄 Client Config saved at: $WG_DIR/${CLIENT_NAME}.conf${NC}"
    echo -e "${BLUE}📷 QR Code for Mobile Clients:${NC}"
    qrencode -t ansiutf8 < $WG_DIR/${CLIENT_NAME}.conf
}

# Main script
check_root

# Parse command line options
case "$1" in
    -i|--install)
        check_platform
        install_wireguard
        ;;
    -u|--uninstall)
        check_platform
        uninstall_wireguard
        ;;
    -s|--show)
        show_config
        ;;
    *)
        echo "Usage: $0 [-i|--install] [-u|--uninstall] [-s|--show]"
        echo "Options:"
        echo "  -i, --install    Install WireGuard"
        echo "  -u, --uninstall  Uninstall WireGuard"
        echo "  -s, --show       Show current configuration"
        exit 1
        ;;
esac
