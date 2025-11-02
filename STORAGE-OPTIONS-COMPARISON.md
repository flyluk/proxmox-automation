# Kubernetes Storage Options Comparison

## TL;DR - Which to Choose?

| Use Case | Recommended Option | Complexity |
|----------|-------------------|------------|
| **Testing/Development** | Local Path | ⭐ Easy |
| **Simple shared storage** | NFS | ⭐⭐ Medium |
| **Production with Proxmox** | Proxmox CSI | ⭐⭐⭐ Medium |
| **Enterprise with ZFS** | TrueNAS + iSCSI | ⭐⭐⭐⭐ Complex |

## Option 1: Local Path Storage (Simplest)

### Pros:
- ✅ No additional setup required
- ✅ Works immediately
- ✅ Fast (local disk)
- ✅ No network overhead

### Cons:
- ❌ Storage tied to specific node
- ❌ Pod can't move to another node
- ❌ No shared storage between pods

### Setup:
```bash
./setup-local-path-storage.sh
```

### Best for:
- Development/testing
- Stateless applications
- Single-node clusters
- Databases that handle replication (MongoDB, Cassandra)

---

## Option 2: NFS Storage (Recommended for Most)

### Pros:
- ✅ Shared storage across all nodes
- ✅ Simple to setup
- ✅ Pods can move between nodes
- ✅ ReadWriteMany support
- ✅ Uses existing Proxmox host

### Cons:
- ❌ Slower than local storage
- ❌ Network dependency
- ❌ No advanced features (snapshots, clones)

### Setup:
```bash
./setup-nfs-storage.sh proxmox.test.local /mnt/k8s-storage
```

### Best for:
- **Most production workloads**
- Shared file storage
- WordPress, web apps
- CI/CD artifacts
- Log aggregation

---

## Option 3: Proxmox CSI Plugin (Native Integration)

### Pros:
- ✅ Native Proxmox integration
- ✅ Uses Proxmox storage (LVM, ZFS, Ceph)
- ✅ No additional VM needed
- ✅ Snapshots support
- ✅ Dynamic provisioning

### Cons:
- ❌ More complex setup
- ❌ Requires Proxmox API access
- ❌ Limited documentation
- ❌ ReadWriteOnce only

### Setup:
```bash
# Create API token in Proxmox first
./setup-proxmox-csi.sh proxmox.test.local "PVEAPIToken=root@pam!k8s=xxx"
```

### Best for:
- Production on Proxmox
- Block storage needs
- When you want Proxmox-native features
- Databases requiring fast I/O

---

## Option 4: TrueNAS + iSCSI (Enterprise)

### Pros:
- ✅ Enterprise-grade features
- ✅ ZFS benefits (snapshots, compression, dedup)
- ✅ Full REST API
- ✅ Web UI management
- ✅ Proven reliability

### Cons:
- ❌ **Most complex setup**
- ❌ Requires dedicated VM
- ❌ More resources (8GB RAM minimum)
- ❌ Additional management overhead

### Setup:
```bash
./setup-truenas-vm.sh proxmox.test.local 200 100
# ... follow TRUENAS-COMPLETE-SETUP.md
```

### Best for:
- Large production deployments
- When you need ZFS features
- Multiple Kubernetes clusters
- Compliance requirements (snapshots, auditing)

---

## Quick Decision Tree

```
Do you need shared storage?
├─ NO → Use Local Path Storage
└─ YES
   └─ Do you need advanced features (snapshots, clones)?
      ├─ NO → Use NFS Storage
      └─ YES
         └─ Already have TrueNAS/FreeNAS?
            ├─ YES → Use TrueNAS + iSCSI
            └─ NO
               └─ Want to manage via Proxmox?
                  ├─ YES → Use Proxmox CSI
                  └─ NO → Use NFS Storage
```

---

## Performance Comparison

| Storage Type | Read Speed | Write Speed | Latency | Network |
|--------------|------------|-------------|---------|---------|
| Local Path   | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Lowest  | None    |
| NFS          | ⭐⭐⭐     | ⭐⭐       | Medium  | Required|
| Proxmox CSI  | ⭐⭐⭐⭐   | ⭐⭐⭐⭐   | Low     | Required|
| iSCSI        | ⭐⭐⭐⭐   | ⭐⭐⭐⭐   | Low     | Required|

---

## My Recommendation

### For Your Setup (MicroK8s on Proxmox):

**Start with NFS** (`./setup-nfs-storage.sh`)

Why?
1. Simple setup (5 minutes)
2. Works with existing Proxmox host
3. Shared storage for all pods
4. Good enough for 90% of workloads
5. Can migrate to iSCSI/Proxmox CSI later if needed

**Upgrade to Proxmox CSI or TrueNAS later** if you need:
- Better performance
- Snapshots/clones
- Block storage
- Enterprise features

---

## Example Usage

### Local Path
```yaml
storageClassName: local-path
```

### NFS
```yaml
storageClassName: nfs-storage
```

### Proxmox CSI
```yaml
storageClassName: proxmox-storage
```

### TrueNAS iSCSI
```yaml
storageClassName: iscsi-storage
```

---

## Migration Path

1. **Start**: Local Path (testing)
2. **Grow**: NFS (production)
3. **Scale**: Proxmox CSI or TrueNAS (enterprise)

You can run multiple storage classes simultaneously!
