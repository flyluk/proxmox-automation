#!/bin/bash

# Configure TrueNAS for Kubernetes iSCSI storage via API
# Usage: ./configure-truenas.sh <truenas-ip> <api-key>

TRUENAS_IP="${1}"
API_KEY="${2}"

if [ -z "$TRUENAS_IP" ]; then
    echo "Usage: ./configure-truenas.sh <truenas-ip> <api-key>"
    echo ""
    echo "To get API key:"
    echo "1. Login to TrueNAS web UI: http://<truenas-ip>"
    echo "2. Top-right → Settings → API Keys"
    echo "3. Click 'Add' → Name: 'kubernetes' → Save"
    echo "4. Copy the generated key"
    exit 1
fi

if [ -z "$API_KEY" ]; then
    echo "API key required. Get it from TrueNAS web UI:"
    echo "Settings → API Keys → Add"
    exit 1
fi

API_URL="http://$TRUENAS_IP/api/v2.0"

echo "Configuring TrueNAS at $TRUENAS_IP..."

# Get available disks
echo "Available disks:"
curl -s -X GET "$API_URL/disk" -H "Authorization: Bearer $API_KEY" | jq -r '.[] | "\(.name) - \(.size/1024/1024/1024)GB"'

# Create ZFS pool (adjust disk name as needed)
echo ""
read -p "Enter disk name for ZFS pool (e.g., sdb): " DISK_NAME

curl -s -X POST "$API_URL/pool" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"tank\",
        \"topology\": {
            \"data\": [{
                \"type\": \"STRIPE\",
                \"disks\": [\"$DISK_NAME\"]
            }]
        }
    }" | jq .

# Create datasets
curl -s -X POST "$API_URL/pool/dataset" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"name": "tank/k8s"}' | jq .

curl -s -X POST "$API_URL/pool/dataset" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"name": "tank/k8s/iscsi"}' | jq .

curl -s -X POST "$API_URL/pool/dataset" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"name": "tank/k8s/iscsi-snapshots"}' | jq .

# Enable iSCSI service
curl -s -X PUT "$API_URL/service/id/iscsitarget" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"enable": true}' | jq .

curl -s -X POST "$API_URL/service/start" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"service": "iscsitarget"}' | jq .

# Create portal
curl -s -X POST "$API_URL/iscsi/portal" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "comment": "Kubernetes Portal",
        "listen": [{"ip": "0.0.0.0"}]
    }' | jq .

# Create initiator group (allow all)
curl -s -X POST "$API_URL/iscsi/initiator" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "comment": "Kubernetes Initiators",
        "initiators": []
    }' | jq .

echo ""
echo "✓ TrueNAS configured for Kubernetes iSCSI storage"
echo ""
echo "Configuration details:"
echo "  Target Portal: $TRUENAS_IP:3260"
echo "  ZFS Pool: tank"
echo "  Dataset: tank/k8s/iscsi"
echo "  API Key: $API_KEY"
echo ""
echo "Update democratic-csi-iscsi-values.yaml with:"
echo "  httpConnection.host: $TRUENAS_IP"
echo "  httpConnection.apiKey: $API_KEY"
echo "  zfs.datasetParentName: tank/k8s/iscsi"
echo "  iscsi.targetPortal: $TRUENAS_IP:3260"
