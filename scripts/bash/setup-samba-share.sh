#!/bin/bash
set -euo pipefail

echo "=== Setting up Samba with AD auth ==="

sudo apt install -y samba winbind

sudo mkdir -p /srv/shares/{allgemein,entwicklung}
sudo chown root:root /srv/shares/allgemein /srv/shares/entwicklung
sudo chmod 770 /srv/shares/allgemein /srv/shares/entwicklung

sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

cat <<'EOF' | sudo tee /etc/samba/smb.conf
[global]
    workgroup = CORP
    realm = CORP.GMBH
    security = ADS
    idmap config * : range = 10000-20000
    log file = /var/log/samba/%m.log
    log level = 1

[Allgemein]
    path = /srv/shares/allgemein
    read only = no
    valid users = @"CORP\GRP-FileShare-Allgemein"
    force group = "CORP\GRP-FileShare-Allgemein"
    create mask = 0660
    directory mask = 0770

[Entwicklung]
    path = /srv/shares/entwicklung
    read only = no
    valid users = @"CORP\GRP-Dept-Entwicklung" @"CORP\GRP-Dept-IT"
    create mask = 0660
    directory mask = 0770
EOF

sudo systemctl restart smbd nmbd
echo "Samba shares configured successfully."
echo "Test with: smbclient -L localhost -U anna.becker"