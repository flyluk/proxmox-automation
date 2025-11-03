# Proxmox iSCSI Target Setup - Detailed Guide

## Point 2: iSCSI Target Service Configuration

### What is iSCSI Target?
- **iSCSI Target** = Storage server that shares block devices over network
- **iSCSI Initiator** = Client (Kubernetes nodes) that connects to target
- Think of it as "network-attached hard drives"

### Option A: Using targetcli (Recommended for Proxmox)

#### Step 1: Install targetcli
```bash
ssh proxmox.test.local
apt update
apt install -y targetcli-fb
```

#### Step 2: Enable Services
```bash
systemctl enable --now rtslib-fb-targetctl
systemctl enable --now target
systemctl status target
```

#### Step 3: Configure iSCSI Target with targetcli
```bash
targetcli
```

Inside targetcli interactive shell:

**3.1 Create Backstore (Storage Backend)**
```bash
# Using ZFS zvol
/backstores/block create name=k8s-block dev=/dev/zvol/rpool/k8s/test-volume

# Or using file-based (for testing)
/backstores/fileio create name=k8s-file /k8s/iscsi/test.img 10G
```

**3.2 Create iSCSI Target**
```bash
# Create target with IQN (iSCSI Qualified Name)
/iscsi create iqn.2024-01.local.proxmox:k8s-target
```

**3.3 Create LUN (Logical Unit Number)**
```bash
# Attach backstore to target
/iscsi/iqn.2024-01.local.proxmox:k8s-target/tpg1/luns create /backstores/block/k8s-block
```

**3.4 Configure Access Control**
```bash
# Allow any initiator (for testing)
/iscsi/iqn.2024-01.local.proxmox:k8s-target/tpg1 set attribute authentication=0
/iscsi/iqn.2024-01.local.proxmox:k8s-target/tpg1 set attribute generate_node_acls=1
/iscsi/iqn.2024-01.local.proxmox:k8s-target/tpg1 set attribute demo_mode_write_protect=0

# Or create specific ACL for security
/iscsi/iqn.2024-01.local.proxmox:k8s-target/tpg1/acls create iqn.2024-01.local.k8s:initiator
```

**3.5 Configure Portal (Network Binding)**
```bash
# Default listens on all interfaces (0.0.0.0:3260)
# To specify IP:
/iscsi/iqn.2024-01.local.proxmox:k8s-target/tpg1/portals create 192.168.1.100 3260
```

**3.6 Save Configuration**
```bash
saveconfig
exit
```

#### Step 4: Verify Configuration
```bash
# Check target status
targetcli ls

# Should show structure like:
# /iscsi/iqn.2024-01.local.proxmox:k8s-target/tpg1
#   ├── acls
#   ├── luns
#   │   └── lun0 -> /backstores/block/k8s-block
#   └── portals
#       └── 0.0.0.0:3260

# Check if service is listening
ss -tlnp | grep 3260
```

### Option B: Using TrueNAS (Easier GUI Method)

If you prefer GUI, install TrueNAS as a VM on Proxmox:

#### Step 1: Create TrueNAS VM
```bash
# Download TrueNAS ISO
wget https://download.truenas.com/TrueNAS-SCALE-Latest/TrueNAS-SCALE-Latest.iso

# Create VM in Proxmox
qm create 200 --name truenas --memory 8192 --cores 4 --net0 virtio,bridge=vmbr0
qm set 200 --ide2 /path/to/TrueNAS-SCALE-Latest.iso,media=cdrom
qm set 200 --scsi0 local-lvm:100
qm start 200
```

#### Step 2: Configure TrueNAS (via Web UI)
1. Access TrueNAS at `http://truenas-ip`
2. **Storage** → Create ZFS pool
3. **Sharing** → **Block (iSCSI)**
4. **Portals** → Add portal (0.0.0.0:3260)
5. **Initiators** → Add initiator group (allow all or specific IQNs)
6. **Targets** → Create target
7. **Extents** → Create extent (zvol or file)
8. **Associated Targets** → Link target + extent

## Point 3: API Access Configuration

Democratic CSI needs API access to automatically create/delete volumes.

### For targetcli (Manual API - Not Recommended)
targetcli doesn't have built-in REST API. You need to:
1. Use TrueNAS instead (has REST API)
2. Or build custom API wrapper around targetcli commands

### For TrueNAS (Recommended)

#### Step 1: Create API Key
```bash
# Via Web UI:
# 1. Top-right corner → Settings → API Keys
# 2. Click "Add"
# 3. Name: "kubernetes-csi"
# 4. Copy the generated key

# Via CLI:
ssh truenas.test.local
midclt call api_key.create '{"name": "kubernetes-csi", "allowlist": [{"method": "*", "resource": "*"}]}'
```

#### Step 2: Test API Access
```bash
# Get API key
API_KEY="your-api-key-here"
TRUENAS_IP="192.168.1.100"

# Test API call
curl -X GET "http://$TRUENAS_IP/api/v2.0/pool/dataset" \
  -H "Authorization: Bearer $API_KEY"
```

#### Step 3: Configure Democratic CSI Values
```yaml
driver:
  config:
    driver: freenas-iscsi
    httpConnection:
      protocol: http
      host: 192.168.1.100
      port: 80
      apiKey: your-api-key-here  # Use API key instead of username/password
    zfs:
      datasetParentName: tank/k8s/iscsi
    iscsi:
      targetPortal: "192.168.1.100:3260"
      targetGroups:
        - targetGroupPortalGroup: 1    # Portal ID from TrueNAS
          targetGroupInitiatorGroup: 1  # Initiator group ID
          targetGroupAuthType: None
```

## Complete Workflow Example

### Scenario: Proxmox with targetcli + Manual Management

**1. Create ZFS datasets**
```bash
zfs create rpool/k8s
zfs create rpool/k8s/iscsi
```

**2. For each PVC, manually create:**
```bash
# Create zvol
zfs create -V 10G rpool/k8s/iscsi/pvc-001

# Add to targetcli
targetcli /backstores/block create pvc-001 /dev/zvol/rpool/k8s/iscsi/pvc-001
targetcli /iscsi/iqn.2024-01.local.proxmox:k8s/tpg1/luns create /backstores/block/pvc-001
```

**Problem:** Manual work for each volume ❌

### Scenario: TrueNAS with Democratic CSI (Automated)

**1. Setup TrueNAS once**
- Install TrueNAS
- Create ZFS pool
- Configure iSCSI service
- Create API key

**2. Install Democratic CSI**
```bash
./setup-iscsi-storage.sh
# Edit values file
helm install democratic-csi-iscsi democratic-csi/democratic-csi -n democratic-csi -f democratic-csi-iscsi-values.yaml
```

**3. Create PVC**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
spec:
  storageClassName: iscsi-storage
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 10Gi
```

**What happens automatically:**
1. CSI driver calls TrueNAS API
2. Creates zvol: `tank/k8s/iscsi/pvc-abc123`
3. Creates iSCSI target: `iqn.2024-01.local.truenas:csi-pvc-abc123`
4. Configures extent and associates with target
5. Kubernetes node discovers and connects to iSCSI target
6. Volume mounted to pod

**Result:** Fully automated ✅

## Quick Start Script

Run the automated setup:
```bash
chmod +x setup-proxmox-iscsi-target.sh
./setup-proxmox-iscsi-target.sh proxmox.test.local
```

This will:
- Install targetcli
- Create ZFS datasets
- Configure basic iSCSI target
- Display connection details

## Verification Commands

```bash
# On Proxmox/TrueNAS
targetcli ls                    # View iSCSI configuration
zfs list -r rpool/k8s          # View ZFS datasets
ss -tlnp | grep 3260           # Check iSCSI port

# On Kubernetes nodes
sudo iscsiadm -m discovery -t st -p 192.168.1.100:3260  # Discover targets
sudo iscsiadm -m node                                    # List nodes
sudo iscsiadm -m session                                 # Active sessions
```
