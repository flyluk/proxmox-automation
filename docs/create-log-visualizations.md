# Create Log Count Over Time Visualization

## Steps:

1. **Access OpenSearch Dashboards**
   ```bash
   kubectl port-forward -n opensearch svc/opensearch-dashboards 5601:5601
   ```
   Open: http://localhost:5601
   Login: admin / admin

2. **Create Index Pattern** (if not done)
   - Go to: **Management** → **Index Patterns**
   - Click **Create index pattern**
   - Index pattern: `fluent-bit*`
   - Time field: `@timestamp`
   - Click **Create**

3. **Create Visualization**
   - Go to: **Visualize** → **Create visualization**
   - Select: **Line** (or **Area** for filled chart)
   - Choose index: `fluent-bit*`

4. **Configure Metrics**
   - Y-axis:
     - Aggregation: **Count**
     - Custom label: `Log Count`

5. **Configure Buckets**
   - X-axis:
     - Aggregation: **Date Histogram**
     - Field: `@timestamp`
     - Interval: **Auto** (or choose: 1m, 5m, 1h)
     - Custom label: `Time`

6. **Add Filters** (Optional)
   - Click **Add filter**
   - Examples:
     - `kubernetes.namespace_name: "default"`
     - `log: *error*`

7. **Save Visualization**
   - Click **Save**
   - Title: `K8s Log Count Over Time`
   - Click **Save**

8. **Add to Dashboard**
   - Go to: **Dashboard** → **Create dashboard**
   - Click **Add** → Select your visualization
   - Arrange and resize
   - Click **Save** → Name: `K8s Logs Dashboard`

## Quick Filters to Add:

- **By Namespace**: `kubernetes.namespace_name`
- **By Pod**: `kubernetes.pod_name`
- **By Container**: `kubernetes.container_name`
- **Error Logs**: `log: *error* OR log: *ERROR*`
