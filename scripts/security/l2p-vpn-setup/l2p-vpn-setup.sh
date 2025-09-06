#!/bin/bash

##############################################################################
# Script Name: l2p-vpn-setup.sh
# Description: Sets up strongSwan L2TP/IPsec VPN client configuration
# Author: Original script author
# Version: 2.0
# Last Modified: 2025-09-06
#
# Usage: sudo ./l2p-vpn-setup.sh
#
# Requirements:
#   - Root privileges
#   - Fedora/RHEL/CentOS system with dnf package manager
#   - Environment variables set for VPN configuration
#
# Environment Variables (Required):
#   - VPN_SERVER_IP: Your VPN server's IP address
#   - VPN_USER: Your VPN username
#   - VPN_PASSWORD: Your VPN password
#   - IPSEC_PSK: Your IPsec Pre-Shared Key
#
# Exit Codes:
#   0 - Success
#   1 - Missing environment variables
#   2 - Not running as root
##############################################################################

set -euo pipefail

# ==============================================================================
# == CONFIGURATION VALIDATION                                                 ==
# ==============================================================================

# Load configuration from environment variables
VPN_SERVER_IP="${VPN_SERVER_IP:-}"
VPN_USER="${VPN_USER:-}"
VPN_PASSWORD="${VPN_PASSWORD:-}"
IPSEC_PSK="${IPSEC_PSK:-}"

# Validate required configuration
if [ -z "$VPN_SERVER_IP" ] || [ -z "$VPN_USER" ] || [ -z "$VPN_PASSWORD" ] || [ -z "$IPSEC_PSK" ]; then
    echo "❌ Error: Missing required environment variables."
    echo "Please set the following environment variables:"
    echo "  export VPN_SERVER_IP='your_vpn_server_ip'"
    echo "  export VPN_USER='your_username'"
    echo "  export VPN_PASSWORD='your_password'"
    echo "  export IPSEC_PSK='your_ipsec_psk'"
    echo ""
    echo "Or source a .env file with these variables."
    exit 1
fi

# ==============================================================================

echo "🚀 Starting strongSwan VPN Setup..."
if [ "$EUID" -ne 0 ]; then echo "❌ Error: Must be run as root." && exit 1; fi

# 1. Clean up old software and configs
echo "🗑️  Removing Libreswan and old configs..."
dnf remove -y libreswan &>/dev/null
rm -f /etc/strongswan/ipsec.conf /etc/strongswan/ipsec.secrets
rm -rf /etc/systemd/system/ipsec.service.d

# 2. Install strongSwan
echo "📦 Installing strongswan, xl2tpd, ppp..."
dnf install -y strongswan xl2tpd ppp strongswan-sqlite

# 3. Create Modern swanctl IPsec Configuration (IN THE CORRECT PATH)
echo "🔧 Creating modern swanctl configuration..."
# CORRECTED FILE PATH on the next two lines
mkdir -p /etc/strongswan/swanctl/conf.d
cat << EOF > /etc/strongswan/swanctl/conf.d/idrac-vpn.conf
connections {
    idrac-vpn {
        version = 1
        remote_addrs = $VPN_SERVER_IP
        local_addrs = 0.0.0.0
        proposals = aes128-sha1-modp2048

        local {
            auth = psk
        }
        remote {
            auth = psk
        }
        children {
            idrac-vpn {
                mode = transport
                esp_proposals = aes128-sha1
                local_ts  = 0.0.0.0/0[udp/l2tp]
                remote_ts = 0.0.0.0/0[udp/l2tp]
            }
        }
    }
}

secrets {
    ike-1 {
        id = $VPN_SERVER_IP
        secret = "$IPSEC_PSK"
    }
}
EOF

# 4. Create xl2tpd and PPP configurations
echo "🔧 Creating xl2tpd and PPP configurations..."
cat << EOF > /etc/xl2tpd/xl2tpd.conf
[lac idrac-vpn]
lns = $VPN_SERVER_IP
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF
cat << EOF > /etc/ppp/options.l2tpd.client
ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-mschap-v2
noccp
noauth
idle 1800
mtu 1410
mru 1410
defaultroute
usepeerdns
debug
connect-delay 5000
name "$VPN_USER"
password "$VPN_PASSWORD"
EOF
chmod 600 /etc/ppp/options.l2tpd.client

# 5. Create Helper Scripts
echo "⚙️  Creating helper scripts..."
cat << 'EOF' > /usr/local/sbin/vpn-connect
#!/bin/bash
echo "Loading swanctl configuration..."
swanctl --load-all
echo "Bringing up IPsec tunnel..."
swanctl --initiate --child idrac-vpn
sleep 4
echo "Starting xl2tpd and connecting..."
systemctl restart xl2tpd
sleep 2
echo "c idrac-vpn" > /var/run/xl2tpd/l2tp-control
sleep 5
echo "VPN Status:"
ip a show ppp0 || echo "Connection failed. Check 'journalctl -u strongswan -n 50' and 'journalctl -u xl2tpd -n 50'"
EOF
cat << 'EOF' > /usr/local/sbin/vpn-disconnect
#!/bin/bash
echo "Disconnecting L2TP..."
echo "d idrac-vpn" > /var/run/xl2tpd/l2tp-control
sleep 2
echo "Bringing down IPsec tunnel..."
swanctl --terminate --child idrac-vpn
EOF
chmod +x /usr/local/sbin/vpn-connect /usr/local/sbin/vpn-disconnect

# 6. Enable and start services
echo "🔄 Enabling and starting services..."
systemctl daemon-reload
systemctl enable strongswan.service
systemctl enable xl2tpd
systemctl restart strongswan.service

echo -e "\n🎉 All done. The system is now using the modern swanctl configuration."
echo "   To connect:    sudo vpn-connect"
echo "   To disconnect: sudo vpn-disconnect"
