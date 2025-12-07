# Loki Troubleshooting Guide

## Quick Check: Is Loki Working?

### 1. Check Promtail is Collecting Logs

```bash
# SSH to Master-1
ssh -i terraform/simple-k8s/dhakacart-k8s-key.pem ubuntu@54.251.183.40
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@10.0.10.82

# Check positions file (should NOT be empty)
kubectl exec -n monitoring daemonset/promtail -- cat /run/promtail/positions.yaml
```

**Expected**: Should show file paths with byte positions (not empty)

### 2. Check Promtail Logs

```bash
kubectl logs -n monitoring daemonset/promtail --tail=50
```

**Look for**: 
- ✅ `tail routine: started` - Promtail is reading files
- ✅ `watching new directory` - Promtail found log directories
- ❌ Any errors

### 3. Query Loki in Grafana

**URL**: http://dhakacart-k8s-alb-4719103.ap-southeast-1.elb.amazonaws.com/grafana/

**Steps**:
1. Go to **Explore** (compass icon on left sidebar)
2. Select **Loki** datasource from dropdown
3. Use **Builder** mode (not Code)
4. Click **Label filters** → Select:
   - Label: `job`
   - Value: `kubernetes-pods`
5. Set time range to **Last 1 hour** (top right)
6. Click **Run query** button

**Alternative queries to try**:

```logql
# All logs
{job="kubernetes-pods"}

# DhakaCart namespace only
{job="kubernetes-pods", namespace="dhakacart"}

# Backend container
{job="kubernetes-pods", container="backend"}

# Search for specific text
{job="kubernetes-pods"} |= "error"
```

## Common Issues

### Issue 1: "No logs volume available"

**Causes**:
- Time range is wrong (try "Last 1 hour" or "Last 6 hours")
- Labels don't match (use `job="kubernetes-pods"` not `namespace="dhakacart"` initially)
- Logs haven't been ingested yet (wait 1-2 minutes)

**Solution**:
1. Set time range to **Last 1 hour**
2. Use simple query: `{job="kubernetes-pods"}`
3. Wait 30 seconds and refresh

### Issue 2: Positions file is empty

**Solution**:
```bash
# Restart Promtail
kubectl rollout restart daemonset/promtail -n monitoring

# Wait 30 seconds
sleep 30

# Check again
kubectl exec -n monitoring daemonset/promtail -- cat /run/promtail/positions.yaml
```

### Issue 3: Promtail not finding logs

**Check log files exist**:
```bash
kubectl exec -n monitoring daemonset/promtail -- ls -la /var/log/pods/ | head -20
```

**Should show**: Directories like `dhakacart_dhakacart-backend-...`

## Verification Commands

### From Master-1

```bash
# Check all monitoring pods
kubectl get pods -n monitoring

# Check Promtail config
kubectl get configmap -n monitoring promtail-config -o yaml

# Check Loki service
kubectl get svc -n monitoring loki

# Test Loki endpoint
kubectl exec -n monitoring deployment/loki -- wget -qO- http://localhost:3100/ready
```

## Expected Working State

When everything is working:

1. **Promtail positions file**: Shows file paths with byte counts
2. **Promtail logs**: Shows "tail routine: started" messages
3. **Grafana Loki**: Shows logs when querying `{job="kubernetes-pods"}`

## Getting Help

If logs still don't appear after following this guide:

1. Check Promtail logs for errors
2. Verify time range in Grafana (use "Last 1 hour")
3. Try the simplest query first: `{job="kubernetes-pods"}`
4. Wait 1-2 minutes for logs to be indexed

## Quick Test Script

```bash
#!/bin/bash
echo "=== Checking Loki Setup ==="

echo "1. Promtail pods:"
kubectl get pods -n monitoring | grep promtail

echo -e "\n2. Positions file (first 10 lines):"
kubectl exec -n monitoring daemonset/promtail -- cat /run/promtail/positions.yaml | head -10

echo -e "\n3. Recent Promtail activity:"
kubectl logs -n monitoring daemonset/promtail --tail=5

echo -e "\n4. Loki pod:"
kubectl get pods -n monitoring | grep loki

echo -e "\n=== If all above look good, logs should be in Grafana ==="
```

Save this as `check-loki.sh` and run from Master-1.
