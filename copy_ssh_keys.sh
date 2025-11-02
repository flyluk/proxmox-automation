#!/bin/bash

# Usage: ./copy_ssh_keys.sh <host> <user> <password>

if [ $# -ne 3 ]; then
    echo "Usage: $0 <host> <user> <password>"
    exit 1
fi

HOST=$1
USER=$2
PASS=$3

# Install sshpass if not available
if ! command -v sshpass &> /dev/null; then
    echo "Installing sshpass..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y sshpass
    elif command -v yum &> /dev/null; then
        sudo yum install -y sshpass
    else
        echo "Cannot install sshpass. Please install manually."
        exit 1
    fi
fi

# Remove known_hosts entry for the target host
ssh-keygen -R "$HOST" 2>/dev/null

# Copy id_rsa and id_rsa.pub to target system
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no ~/.ssh/id_rsa ~/.ssh/id_rsa.pub "$USER@$HOST:~/.ssh/"

# Add public key to authorized_keys
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no "$USER@$HOST" "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"

echo "SSH keys copied and authorized_keys updated on $USER@$HOST"