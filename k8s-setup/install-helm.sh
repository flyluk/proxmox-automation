#!/bin/bash

# Install Helm
# Usage: ./install-helm.sh

echo "Installing Helm..."

# Download and install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version

echo "✓ Helm installed successfully"
