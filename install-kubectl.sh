#!/bin/bash

# Install kubectl
# Usage: ./install-kubectl.sh

echo "Installing kubectl..."

# Download latest stable kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Clean up
rm kubectl

# Verify installation
kubectl version --client

echo "✓ kubectl installed successfully"
