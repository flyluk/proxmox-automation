#!/bin/bash

# Download Ubuntu 24.04 cloud image
echo "Downloading Ubuntu 24.04 cloud image..."
wget -O noble-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

# Download NVIDIA driver
echo "Downloading NVIDIA driver..."
wget -O NVIDIA-Linux-x86_64-580.95.05.run https://us.download.nvidia.com/tesla/580.95.05/NVIDIA-Linux-x86_64-580.95.05.run

echo "Downloads completed."