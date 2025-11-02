#!/bin/bash

# Usage: ./setup-proxmox.sh <host>
# Run after copy_ssh_keys.sh to use SSH key authentication

if [ $# -ne 1 ]; then
    echo "Usage: $0 <host>"
    exit 1
fi

HOST=$1

# SSH into target system and setup
ssh -o StrictHostKeyChecking=no "root@$HOST" << 'EOF'
cd /tmp
git clone https://github.com/flyluk/proxmox-automation.git
cd proxmox-automation
chmod +x download-files.sh
./download-files.sh
sudo mv noble-server-cloudimg-amd64.img /var/lib/vz/template/iso/
sudo mkdir -p /var/lib/vz/snippets
sudo cp cloud-init-runcmd.yaml /var/lib/vz/snippets/
echo "Setup completed successfully"
EOF