#!/bin/bash

# Setup iSCSI StorageClass with Democratic CSI
# Usage: ./setup-iscsi-storage.sh

echo "Installing Democratic CSI for iSCSI..."

# Add Democratic CSI Helm repo
helm repo add democratic-csi https://democratic-csi.github.io/charts/
helm repo update

# Create namespace
kubectl create namespace democratic-csi 2>/dev/null || true

# Create values file
cat > democratic-csi-iscsi-values.yaml <<'EOF'
csiDriver:
  name: "org.democratic-csi.iscsi"

storageClasses:
- name: iscsi-storage
  defaultClass: false
  reclaimPolicy: Delete
  volumeBindingMode: Immediate
  allowVolumeExpansion: true
  parameters:
    fsType: ext4

driver:
  config:
    driver: freenas-iscsi
    instance_id:
    httpConnection:
      protocol: http
      host: YOUR_ISCSI_TARGET_IP
      port: 80
      username: YOUR_USERNAME
      password: YOUR_PASSWORD
      allowInsecure: true
    zfs:
      datasetParentName: pool/k8s/iscsi
      detachedSnapshotsDatasetParentName: pool/k8s/iscsi-snapshots
      datasetEnableQuotas: true
      datasetEnableReservation: false
      datasetPermissionsMode: "0777"
    iscsi:
      targetPortal: "YOUR_ISCSI_TARGET_IP:3260"
      interface:
      namePrefix: csi-
      nameSuffix: "-cluster"
      targetGroups:
        - targetGroupPortalGroup: 1
          targetGroupInitiatorGroup: 1
          targetGroupAuthType: None
      extentInsecureTpc: true
      extentXenCompat: false
      extentDisablePhysicalBlocksize: true
      extentBlocksize: 512
      extentRpm: "SSD"
      extentAvailThreshold: 0
EOF

echo "✓ Created democratic-csi-iscsi-values.yaml"
echo ""
echo "Edit democratic-csi-iscsi-values.yaml with your iSCSI target details, then run:"
echo "  helm install democratic-csi-iscsi democratic-csi/democratic-csi -n democratic-csi -f democratic-csi-iscsi-values.yaml"
