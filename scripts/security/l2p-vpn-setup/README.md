# L2TP/IPsec VPN Client Setup for Rocky Linux

This guide provides a complete, automated script to configure an **L2TP/IPsec** VPN client on a Rocky Linux server. It uses **strongSwan** and **xl2tpd** for a stable, command-line-managed connection.

After setup, you will have two simple commands — `vpn-connect` and `vpn-disconnect` — to manage your VPN connection.

---

## Prerequisites

Before running the setup script, ensure that **git** is installed to download the setup script itself.

Install git:
```bash
sudo dnf install -y git
```

All other required packages (strongswan, xl2tpd, ppp, and strongswan-sqlite) will be installed automatically by the main setup script.

How to Use
1. Download the Setup Script

Clone the repository or download the l2p-vpn-setup.sh script to your server.

2. Configure Your Credentials

Open the l2p-vpn-setup.sh script with a text editor (like nano or vi) and fill in your VPN details in the USER CONFIGURATION section at the top of the file.

Provide the following values:

- VPN_SERVER_IP: The IP address of the VPN server.
- VPN_USER: Your VPN username.
- VPN_PASSWORD: Your VPN password.
- IPSEC_PSK: The IPsec Pre-Shared Key.

```text
# Your VPN server's IP address
VPN_SERVER_IP="172.240.65.2"

# Your VPN username
VPN_USER="a30079"

# Your VPN password
VPN_PASSWORD="YourSecretPasswordHere"

# Your IPsec Pre-Shared Key (PSK)
IPSEC_PSK="YourPreSharedKeyHere"

```

3. Run the Setup Script

Make the script executable and run it with sudo
```bash
chmod +x l2p-vpn-setup.sh
sudo ./l2p-vpn-setup.sh
```
The script will perform all necessary setup steps automatically.


Managing the VPN Connection

The setup script creates two helper commands to manage your VPN connection.

## To Connect

This command starts the secure IPsec tunnel, connects the L2TP user session, and shows the status of the ppp0 interface.

```bash
vpn-connect
```
To Disconnect

This command disconnects the L2TP user session, stops the IPsec tunnel, and shows the status of the ppp0 interface.

```bash
vpn-disconnect
```
# Troubleshooting

If the connection fails, check the logs for the two services that manage the VPN.

For IPsec/Tunnel issues:
```shell
sudo journalctl -u strongswan -n 50
```
For User connection/PPP issues:

```shell
sudo journalctl -u xl2tpd -n 50
```
