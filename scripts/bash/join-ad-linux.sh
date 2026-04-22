#!/bin/bash
set -euo pipefail

DOMAIN="corp.gmbh"
DC_IP="10.0.0.4"

echo "=== Joining $HOSTNAME to $DOMAIN ==="

echo "[1/6] Syncing system clock..."
sudo timedatectl set-ntp true
sleep 5
timedatectl status | grep "synchronized"

echo "[2/6] Configuring DNS..."
sudo resolvectl dns eth0 $DC_IP
sudo resolvectl domain eth0 $DOMAIN
sleep 2

echo "Testing DNS resolution..."
if ! nslookup $DOMAIN > /dev/null 2>&1; then
    echo "ERROR: Cannot resolve $DOMAIN. Check DNS settings."
    exit 1
fi
echo "DNS OK."

echo "[3/6] Installing packages..."
sudo apt update -qq
sudo apt install -y realmd sssd sssd-tools adcli krb5-user \
    packagekit samba-common-bin oddjob oddjob-mkhomedir

echo "[4/6] Discovering domain..."
realm discover $DOMAIN

echo "[5/6] Joining domain (enter labadmin password when prompted)..."
sudo realm join --user=labadmin $DOMAIN

echo "[6/6] Configuring SSSD..."
sudo sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/' /etc/sssd/sssd.conf
sudo sed -i 's|fallback_homedir = /home/%u@%d|fallback_homedir = /home/%u|' /etc/sssd/sssd.conf

sudo pam-auth-update --enable mkhomedir
sudo systemctl restart sssd

echo "[+] Setting up sudo for IT department..."
echo '%GRP-IT-L2-Admin ALL=(ALL) ALL' | sudo tee /etc/sudoers.d/corp-it-admins
echo '%GRP-IT-L3-Infrastructure ALL=(ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers.d/corp-it-admins
sudo chmod 440 /etc/sudoers.d/corp-it-admins

echo ""
echo "=== Domain join complete ==="
echo "Test with: id thomas.mueller"
echo "Login with: ssh thomas.mueller@$HOSTNAME"