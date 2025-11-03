# Complete TrueNAS Setup for Kubernetes iSCSI Storage

## Overview
This guide sets up TrueNAS as a VM on Proxmox to provide iSCSI storage for Kubernetes with Democratic CSI.

## Step-by-Step Setup

### Step 1: Create TrueNAS VM on Proxmox
```bash
./setup-truenas-vm.sh proxmox.test.local 200 100
```
Parameters:
- `proxmox.test.local` - Proxmox host
- `200` - VM ID for TrueNAS
- `100` - Storage disk size in GB

This will:
- Download TrueNAS SCALE ISO
- Create VM with 8GB RAM, 4 cores
- Add 32GB boot disk + 100GB storage disk
- Start VM for installation

### Step 2: Install TrueNAS OS
1. Open Proxmox web UI → VM 200 → Console
2. Follow TrueNAS installer:
   - Select installation disk (32GB disk)
   - Set root password
   - Wait for installation
   - Reboot when prompted
3. Note the IP address shown on console (e.g., 192.168.1.150)

### Step 3: Initial TrueNAS Web UI Setup
1. Access TrueNAS: `http://192.168.1.150`
2. Login: `root` / your-password
3. Complete initial setup wizard
4. Skip pool creation (we'll do it via API)

### Step 4: Create API Key
1. Top-right corner → Settings → API Keys
2. Click "Add"
3. Name: `kubernetes`
4. Click "Add" (no need to restrict permissions)
5. **Copy the API key** (you won't see it again!)

### Step 5: Configure TrueNAS for Kubernetes
```bash
./configure-truenas.sh 192.168.1.150 "your-api-key-here"
```

When prompted, enter disk name (usually `sdb` - the 100GB disk)

This will:
- Create ZFS pool named `tank`
- Create datasets: `tank/k8s/iscsi` and `tank/k8s/iscsi-snapshots`
- Enable iSCSI service
- Create portal listening on 0.0.0.0:3260
- Create initiator group (allow all)

### Step 6: Install iSCSI Tools on Kubernetes Nodes
```bash
./install-iscsi-tools.sh
```

This installs `open-iscsi` on all MicroK8s nodes.

### Step 7: Install Democratic CSI
```bash
# Generate values file
./setup-iscsi-storage.sh

# Edit with TrueNAS details
nano democratic-csi-iscsi-values.yaml
```

Update these values:
```yaml
driver:
  config:
    httpConnection:
      protocol: http
      host: 192.168.1.150
      port: 80
      apiKey: "your-api-key-here"
    zfs:
      datasetParentName: tank/k8s/iscsi
      detachedSnapshotsDatasetParentName: tank/k8s/iscsi-snapshots
    iscsi:
      targetPortal: "192.168.1.150:3260"
```

Install:
```bash
helm install democratic-csi-iscsi \
  democratic-csi/democratic-csi \
  -n democratic-csi \
  -f democratic-csi-iscsi-values.yaml
```

### Step 8: Verify Installation
```bash
# Check CSI pods
kubectl get pods -n democratic-csi

# Check StorageClass
kubectl get storageclass

# Should see: iscsi-storage
```

### Step 9: Test with PVC
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-iscsi-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: iscsi-storage
  resources:
    requests:
      storage: 5Gi
EOF

# Check PVC status
kubectl get pvc test-iscsi-pvc

# Should show: Bound
```

### Step 10: Verify on TrueNAS
1. TrueNAS UI → Storage → View Disks
2. Should see new zvol: `tank/k8s/iscsi/pvc-xxxxx`
3. Sharing → Block (iSCSI) → Targets
4. Should see new target: `iqn.2024-01.local.truenas:csi-pvc-xxxxx`

## Complete Workflow Summary

```bash
# 1. Create TrueNAS VM
./setup-truenas-vm.sh proxmox.test.local 200 100

# 2. Install TrueNAS OS via console (manual)

# 3. Get API key from web UI (manual)

# 4. Configure TrueNAS
./configure-truenas.sh 192.168.1.150 "api-key"

# 5. Prepare Kubernetes nodes
./install-iscsi-tools.sh

# 6. Setup Democratic CSI
./setup-iscsi-storage.sh
nano democratic-csi-iscsi-values.yaml  # Edit with TrueNAS details
helm install democratic-csi-iscsi democratic-csi/democratic-csi -n democratic-csi -f democratic-csi-iscsi-values.yaml

# 7. Test
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: iscsi-storage
  resources:
    requests:
      storage: 5Gi
EOF
```

## Troubleshooting

### Check CSI Driver Logs
```bash
kubectl logs -n democratic-csi -l app=democratic-csi-controller --tail=50
```

### Check iSCSI Sessions on Nodes
```bash
ssh microk8s-vm1.test.local
sudo iscsiadm -m session
```

### Check TrueNAS iSCSI Service
```bash
# Via API
curl -X GET "http://192.168.1.150/api/v2.0/service?service=iscsitarget" \
  -H "Authorization: Bearer your-api-key"
```

### Common Issues

**PVC stuck in Pending:**
- Check CSI controller logs
- Verify API key is correct
- Ensure iSCSI service is running on TrueNAS

**Node can't connect to iSCSI:**
- Verify `open-iscsi` is installed on nodes
- Check network connectivity: `ping 192.168.1.150`
- Check firewall: `telnet 192.168.1.150 3260`

**API errors:**
- Verify API key hasn't expired
- Check TrueNAS is accessible: `curl http://192.168.1.150`
