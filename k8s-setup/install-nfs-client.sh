#!/bin/bash
set -e

echo "Installing NFS client on all nodes..."

for node in microk8s-vm{1..6}.test.local; do
  echo "Installing on $node..."
  ssh "$node" "sudo apt update && sudo apt install -y nfs-common" &
done

wait
echo "✓ NFS client installed on all nodes"
