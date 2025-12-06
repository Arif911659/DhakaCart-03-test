# 🔧 Fix Grafana Issues - Complete Guide

**Problem**: Grafana accessible but shows "No data" or dashboard import fails  
**Date**: 2025-12-06

---

## Issues Found

1. **Hardcoded ALB DNS** in Grafana deployment
2. **`GF_SERVER_SERVE_FROM_SUB_PATH` set to false** (should be true)
3. **Prometheus datasource URL** might have trailing slash issues
4. **Prometheus not scraping metrics** (node-exporter, pods)

---

## Quick Fix

### Step 1: Update Grafana ALB DNS

```bash
./scripts/update-grafana-alb-dns.sh
```

This will:
- ✅ Get current ALB DNS from Terraform
- ✅ Update Grafana deployment
- ✅ Set `GF_SERVER_SERVE_FROM_SUB_PATH=true`
- ✅ Restart Grafana pod

### Step 2: Diagnose Issues

```bash
./scripts/diagnose-grafana-issues.sh
```

This checks:
- ✅ Pod status
- ✅ Prometheus connectivity
- ✅ Node-exporter pods
- ✅ Prometheus targets
- ✅ Pod annotations

---

## Manual Fix Steps

### Fix 1: Update Grafana Deployment

**On Master-1:**

```bash
# Get current ALB DNS
cd ~/terraform/simple-k8s  # or wherever terraform is
LB_DNS=$(terraform output -raw load_balancer_dns | sed 's|http://||')

# Update deployment
kubectl get deployment grafana -n monitoring -o yaml > /tmp/grafana-deployment.yaml

# Edit ROOT_URL (replace old DNS with new)
sed -i "s|value: \"http://.*/grafana/\"|value: \"http://$LB_DNS/grafana/\"|" /tmp/grafana-deployment.yaml

# Ensure SERVE_FROM_SUB_PATH is true
sed -i 's|GF_SERVER_SERVE_FROM_SUB_PATH.*value: "false"|GF_SERVER_SERVE_FROM_SUB_PATH\n              value: "true"|' /tmp/grafana-deployment.yaml

# Apply
kubectl apply -f /tmp/grafana-deployment.yaml

# Restart
kubectl rollout restart deployment/grafana -n monitoring
kubectl rollout status deployment/grafana -n monitoring
```

### Fix 2: Verify Prometheus Datasource

**Check datasource configuration:**

```bash
kubectl get configmap grafana-datasources -n monitoring -o yaml
```

**Should show:**
```yaml
url: http://prometheus-service.monitoring.svc.cluster.local:9090/prometheus/
```

**If wrong, fix it:**

```bash
# Edit ConfigMap
kubectl edit configmap grafana-datasources -n monitoring

# Change URL to:
url: http://prometheus-service.monitoring.svc.cluster.local:9090/prometheus/

# Restart Grafana
kubectl rollout restart deployment/grafana -n monitoring
```

### Fix 3: Verify Prometheus is Scraping

**Check Prometheus targets:**

```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-service 9090:9090

# Then in browser: http://localhost:9090/prometheus/targets
```

**Or check from pod:**

```bash
PROM_POD=$(kubectl get pod -n monitoring -l app=prometheus-server -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n monitoring $PROM_POD -- wget -q -O- http://localhost:9090/prometheus/api/v1/targets | grep -o '"health":"[^"]*"' | head -10
```

**Expected:** `"health":"up"` for all targets

### Fix 4: Check Node Exporter

**Verify node-exporter is running:**

```bash
kubectl get pods -n monitoring -l app=node-exporter
```

**Should show pods on each node.**

**If missing, check DaemonSet:**

```bash
kubectl get daemonset node-exporter -n monitoring
```

### Fix 5: Verify Pod Annotations

**Backend pods should have:**

```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "5000"
  prometheus.io/path: "/metrics"
```

**Check:**

```bash
kubectl get pod -n dhakacart -l app=dhakacart-backend -o yaml | grep -A 3 annotations
```

**If missing, update deployment:**

```bash
kubectl edit deployment dhakacart-backend -n dhakacart
# Add annotations to pod template
```

---

## Import Dashboard

After fixing configuration:

1. **Access Grafana:**
   ```
   http://<ALB-DNS>/grafana/
   ```
   Username: `admin`
   Password: `dhakacart123`

2. **Import Dashboard:**
   - Go to **Dashboards** → **New** → **Import**
   - Enter Dashboard ID: `315`
   - Click **Load**
   - Select **Prometheus** as Data Source
   - Click **Import**

3. **If still "No data":**
   - Go to **Configuration** → **Data Sources** → **Prometheus**
   - Click **Save & Test**
   - Should show "Data source is working"
   - If not, check Prometheus URL

---

## Troubleshooting

### Issue: Grafana loads but shows blank/error

**Check:**
```bash
# Check Grafana logs
kubectl logs -n monitoring -l app=grafana --tail=50

# Check ROOT_URL
kubectl get deployment grafana -n monitoring -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="GF_SERVER_ROOT_URL")].value}'
```

**Fix:** Update ROOT_URL to match current ALB DNS

### Issue: Prometheus datasource shows "Connection refused"

**Check:**
```bash
# Test from Grafana pod
GRAFANA_POD=$(kubectl get pod -n monitoring -l app=grafana -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n monitoring $GRAFANA_POD -- wget -q -O- http://prometheus-service.monitoring.svc.cluster.local:9090/prometheus/-/healthy
```

**Fix:** Verify Prometheus service name and port

### Issue: Dashboard shows "No data"

**Possible causes:**
1. Prometheus not scraping metrics
2. Time range too narrow
3. Query syntax wrong
4. Metrics don't exist

**Check:**
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-service 9090:9090
# Open: http://localhost:9090/prometheus/targets
```

**Fix:**
- Ensure node-exporter pods running
- Check pod annotations for scraping
- Verify Prometheus RBAC permissions

---

## Verification Checklist

- [ ] Grafana pod is running
- [ ] `GF_SERVER_ROOT_URL` has correct ALB DNS
- [ ] `GF_SERVER_SERVE_FROM_SUB_PATH=true`
- [ ] Prometheus service exists and accessible
- [ ] Grafana datasource URL is correct
- [ ] Node-exporter pods running on all nodes
- [ ] Prometheus targets are "up"
- [ ] Pod annotations for scraping are present
- [ ] Dashboard imports successfully
- [ ] Dashboard shows data

---

**Last Updated**: 2025-12-06  
**Scripts**: 
- `scripts/update-grafana-alb-dns.sh` - Update ALB DNS
- `scripts/diagnose-grafana-issues.sh` - Full diagnostic

