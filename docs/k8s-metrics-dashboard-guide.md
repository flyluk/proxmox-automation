# K8s CPU & RAM Metrics Dashboard

## Install Metrics Collection
```bash
./install-metrics-exporter.sh
```

## Option 1: Use Grafana (Recommended)
Grafana comes with pre-built K8s dashboards:

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80
```
Open: http://localhost:3000 (Login: admin / prom-operator)

**Pre-built Dashboards:**
- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Namespace (Pods)
- Kubernetes / Compute Resources / Node (Pods)
- Kubernetes / Compute Resources / Pod

## Option 2: OpenSearch Dashboards

### Create Metrics Index Pattern
1. Go to **Management** → **Index Patterns**
2. Create pattern: `prometheus-*`
3. Time field: `@timestamp`

### CPU Usage Visualizations

#### 1. CPU Usage by Node (Line Chart)
- **Visualize** → **Line**
- Y-axis: **Average** of `node_cpu_seconds_total`
- X-axis: **Date Histogram**
- Split Series: `node`

#### 2. CPU Usage by Pod (Area Chart)
- **Visualize** → **Area**
- Y-axis: **Average** of `container_cpu_usage_seconds_total`
- X-axis: **Date Histogram**
- Split Series: `pod`
- Filter: Exclude system pods

#### 3. Top CPU Consumers (Data Table)
- **Visualize** → **Data Table**
- Buckets: **Terms** on `pod`
- Metrics: **Average** of `container_cpu_usage_seconds_total`
- Sort: Descending

### RAM Usage Visualizations

#### 4. Memory Usage by Node (Line Chart)
- **Visualize** → **Line**
- Y-axis: **Average** of `node_memory_MemAvailable_bytes`
- X-axis: **Date Histogram**
- Split Series: `node`

#### 5. Memory Usage by Pod (Area Chart)
- **Visualize** → **Area**
- Y-axis: **Average** of `container_memory_usage_bytes`
- X-axis: **Date Histogram**
- Split Series: `pod`

#### 6. Top Memory Consumers (Data Table)
- **Visualize** → **Data Table**
- Buckets: **Terms** on `pod`
- Metrics: **Average** of `container_memory_usage_bytes`
- Sort: Descending

#### 7. Memory Pressure (Gauge)
- **Visualize** → **Gauge**
- Metric: **Average** of `node_memory_MemAvailable_bytes`
- Ranges: Green (>50%), Yellow (20-50%), Red (<20%)

### Network Metrics

#### 8. Network I/O (Line Chart)
- **Visualize** → **Line**
- Y-axis: **Sum** of `container_network_receive_bytes_total`
- X-axis: **Date Histogram**
- Split Series: `pod`

## Create Metrics Dashboard
1. **Dashboard** → **Create dashboard**
2. Add visualizations in grid:
   - Row 1: CPU by Node, Memory by Node
   - Row 2: CPU by Pod, Memory by Pod
   - Row 3: Top CPU consumers, Top Memory consumers
   - Row 4: Memory pressure gauge, Network I/O
3. **Save** as: `K8s Resource Metrics`

## Quick Access
```bash
# Grafana (recommended)
kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80

# OpenSearch Dashboards
kubectl port-forward -n opensearch svc/opensearch-dashboards 5601:5601
```
