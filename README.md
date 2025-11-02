# Proxmox Automation Scripts

Collection of bash scripts for automating Proxmox VE operations including VM creation, template management, and SSH key deployment.

## Scripts

### Setup Scripts
- `setup-proxmox.sh` - Complete Proxmox setup with NVIDIA vGPU support (includes SSH key setup, repository configuration, driver installation, and PCI mapping)
- `copy_ssh_keys.sh` - Copies SSH keys to target system with password authentication
- `download-files.sh` - Downloads required Ubuntu cloud image and NVIDIA driver
- `setup-rag-pipeline.sh` - Clones RAG pipeline repository, creates external Docker volumes, and starts services

### VM Management Scripts
- `create-template.sh` - Creates Ubuntu 24.04 cloud-init template with MicroK8s
- `create-single-vm.sh` - Creates single VM from template
- `create-microk8s-vms.sh` - Creates multiple MicroK8s VMs
- `delete-single-vm.sh` - Deletes single VM
- `remove-microk8s-vms.sh` - Removes multiple VMs
- `add-gpu-to-vm.sh` - Adds NVIDIA GPU support to existing VM with Docker and NVIDIA Container Toolkit

### Kubernetes Tools
- `install-kubectl.sh` - Installs kubectl CLI tool
- `install-helm.sh` - Installs Helm package manager
- `get-kubeconfig.sh` - Retrieves kubeconfig from MicroK8s VM for local kubectl access

### Storage Setup Scripts
- `setup-local-path-storage.sh` - Sets up local-path-provisioner (simplest, no shared storage)
- `setup-nfs-storage.sh` - Sets up NFS storage on Proxmox (recommended for most use cases)
- `setup-proxmox-csi.sh` - Sets up Proxmox CSI plugin for native Proxmox storage
- `setup-hybrid-storage.sh` - Sets up both NFS (RWX) and Proxmox CSI (RWO) storage classes
- `setup-iscsi-storage.sh` - Generates Democratic CSI configuration for iSCSI storage
- `setup-proxmox-iscsi-target.sh` - Configures Proxmox as iSCSI target with targetcli
- `setup-truenas-vm.sh` - Creates TrueNAS VM on Proxmox for enterprise storage
- `configure-truenas.sh` - Configures TrueNAS via API for Kubernetes iSCSI storage
- `install-iscsi-tools.sh` - Installs iSCSI initiator tools on all MicroK8s nodes

### Troubleshooting Scripts
- `fix-storage-simple.sh` - Removes Proxmox CSI and uses NFS only (fixes compatibility issues)
- `fix-networking.sh` - Removes broken Calico installation
- `fix-coredns.sh` - Fixes CoreDNS by restarting MicroK8s DNS addon
- `fix-cni-complete.sh` - Complete CNI cleanup from all nodes
- `fix-cluster-certificates.sh` - Regenerates cluster certificates after IP changes

## Quick Start

### 1. Setup Proxmox with NVIDIA vGPU
```bash
./setup-proxmox.sh <host> <user> <password>
```
This script will:
- Copy SSH keys for passwordless access
- Configure Proxmox repositories (remove subscription, add no-subscription)
- Update and upgrade system
- Install NVIDIA vGPU driver
- Configure PCI mapping for GPU
- Reboot and verify installation

### 2. Create MicroK8s Cluster
```bash
./create-microk8s-vms.sh
```

### 3. Setup Kubernetes Tools
```bash
./install-kubectl.sh
./install-helm.sh
./get-kubeconfig.sh microk8s-vm1.test.local
```

### 4. Setup Storage (Choose One)

**Option A: NFS Storage (Recommended)**
```bash
./setup-nfs-storage.sh proxmox.test.local /mnt/k8s-storage
```

**Option B: Local Path Storage (Simplest)**
```bash
./setup-local-path-storage.sh
```

**Option C: Hybrid Storage (NFS + Proxmox CSI)**
```bash
./setup-hybrid-storage.sh proxmox.test.local "PVEAPIToken=root@pam!k8s=xxx"
```

See `STORAGE-OPTIONS-COMPARISON.md` for detailed comparison.

### 5. Add GPU to VM (Optional)
```bash
./add-gpu-to-vm.sh <vmid>
```
This script will:
- Stop VM if running
- Change VM machine type to q35
- Add GPU with PCI mapping (rombar disabled)
- Start VM and verify GPU presence
- Install NVIDIA drivers in VM
- Install Docker and NVIDIA Container Toolkit
- Test GPU in Docker container

## Requirements

- Proxmox VE 8.x (tested on Trixie)
- NVIDIA GPU with vGPU support
- Ubuntu 24.04 (Noble) for VMs
- SSH access to Proxmox host
- `sshpass` (automatically installed by scripts)
- `qemu-guest-agent` in VMs (included in cloud-init template)

## Usage

Make scripts executable:
```bash
chmod +x *.sh
```

Run scripts with appropriate parameters as documented in each file.

## Documentation

- `STORAGE-OPTIONS-COMPARISON.md` - Comprehensive comparison of all storage options
- `HYBRID-STORAGE-GUIDE.md` - Guide for using both NFS and Proxmox CSI storage
- `ISCSI-SETUP-GUIDE.md` - iSCSI storage setup with Democratic CSI
- `PROXMOX-ISCSI-DETAILED-GUIDE.md` - Detailed Proxmox iSCSI target configuration
- `TRUENAS-COMPLETE-SETUP.md` - Complete TrueNAS setup for enterprise storage

## Features

- **Automated Setup**: Complete Proxmox NVIDIA vGPU configuration in one command
- **Two-Phase Installation**: Handles reboots automatically with polling
- **PCI Mapping**: Automatic GPU detection and PCI device mapping
- **VM GPU Support**: Full GPU passthrough with driver and Docker installation
- **Kubernetes Integration**: Complete MicroK8s cluster setup with storage
- **Multiple Storage Options**: Local, NFS, Proxmox CSI, iSCSI, and TrueNAS support
- **Error Handling**: Comprehensive validation and retry logic
- **Idempotent**: Safe to run multiple times, skips already completed steps