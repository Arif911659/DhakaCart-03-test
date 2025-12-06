# 🔄 Dynamic ALB DNS Update Guide

**Issue**: ALB DNS changes every 4 hours in LAB environments  
**Solution**: Automated script to dynamically update ConfigMap from Terraform output

---

## Problem

In AWS LAB environments, the Application Load Balancer (ALB) DNS name changes every 4 hours when resources are stopped/started. This causes the frontend to break because it has a hardcoded ALB DNS in the ConfigMap.

---

## Solution

Use the automated script `scripts/update-alb-dns-dynamic.sh` that:
1. Gets the current ALB DNS from Terraform output
2. Updates the Kubernetes ConfigMap automatically
3. Restarts frontend pods to apply the new configuration

---

## Quick Start

### Single Command Update

```bash
# From project root
./scripts/update-alb-dns-dynamic.sh
```

This will:
- ✅ Get ALB DNS from Terraform output
- ✅ Update ConfigMap on Master-1
- ✅ Restart frontend pods
- ✅ Verify the update

---

## Manual Update (Alternative)

If the script doesn't work, you can update manually:

### Step 1: Get ALB DNS from Terraform

```bash
cd terraform/simple-k8s
terraform output load_balancer_dns
```

### Step 2: Update ConfigMap on Master-1

```bash
# SSH to Master-1
ssh -i terraform/simple-k8s/dhakacart-k8s-key.pem ubuntu@54.169.237.62
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@10.0.10.128

# Update ConfigMap (replace ALB_DNS with actual DNS)
kubectl patch configmap dhakacart-config -n dhakacart \
  --patch '{"data":{"REACT_APP_API_URL":"http://ALB_DNS/api"}}'

# Restart frontend pods
kubectl rollout restart deployment dhakacart-frontend -n dhakacart

# Wait for rollout
kubectl rollout status deployment/dhakacart-frontend -n dhakacart
```

---

## Complete Deployment Process (v1.0.3)

### Step 1: Build and Push Images

```bash
./scripts/build-and-push-v1.0.3.sh
```

This builds and pushes:
- `arifhossaincse22/dhakacart-backend:v1.0.3`
- `arifhossaincse22/dhakacart-frontend:v1.0.3`

### Step 2: Update ALB DNS

```bash
./scripts/update-alb-dns-dynamic.sh
```

### Step 3: Deploy to Kubernetes

```bash
# On Master-1
kubectl apply -f ~/k8s/deployments/backend-deployment.yaml
kubectl apply -f ~/k8s/deployments/frontend-deployment.yaml

# Wait for rollout
kubectl rollout status deployment/dhakacart-backend -n dhakacart
kubectl rollout status deployment/dhakacart-frontend -n dhakacart

# Verify
kubectl get pods -n dhakacart
```

### Or Use All-in-One Script

```bash
./scripts/deploy-v1.0.3.sh
```

---

## Verification

### Check ConfigMap

```bash
kubectl get configmap dhakacart-config -n dhakacart -o jsonpath='{.data.REACT_APP_API_URL}'
```

Should show: `http://dhakacart-k8s-alb-XXXXX.ap-southeast-1.elb.amazonaws.com/api`

### Check Pod Logs

```bash
kubectl logs -n dhakacart deployment/dhakacart-frontend
```

Look for API URL in the logs.

### Test Site

```bash
# Get ALB DNS
cd terraform/simple-k8s
ALB_DNS=$(terraform output -raw load_balancer_dns)

# Test
curl http://$ALB_DNS/
curl http://$ALB_DNS/api/products
```

---

## Troubleshooting

### Issue: Script fails to connect to Bastion

**Check:**
- Bastion IP is correct: `54.169.237.62`
- SSH key exists: `terraform/simple-k8s/dhakacart-k8s-key.pem`
- Network connectivity

**Fix:**
```bash
# Test connection manually
ssh -i terraform/simple-k8s/dhakacart-k8s-key.pem ubuntu@54.169.237.62
```

### Issue: Terraform output is empty

**Check:**
- Terraform has been applied
- You're in the correct directory: `terraform/simple-k8s`

**Fix:**
```bash
cd terraform/simple-k8s
terraform output  # Check all outputs
terraform refresh  # Refresh state if needed
```

### Issue: ConfigMap update fails

**Check:**
- ConfigMap exists: `kubectl get configmap dhakacart-config -n dhakacart`
- You have permissions on Master-1

**Fix:**
- Update manually using kubectl patch command (see Manual Update section)

### Issue: Frontend still shows old API URL

**Check:**
- ConfigMap was updated: `kubectl get configmap dhakacart-config -n dhakacart -o yaml`
- Frontend pods restarted: `kubectl get pods -n dhakacart`
- Pods are running new image: `kubectl describe pod -n dhakacart -l app=dhakacart-frontend`

**Fix:**
```bash
# Force delete and recreate pods
kubectl delete pods -n dhakacart -l app=dhakacart-frontend
```

---

## Scheduled Update (Cron Job)

For automated updates every 4 hours, you can set up a cron job on your local machine:

```bash
# Add to crontab
crontab -e

# Add this line (runs every 4 hours)
0 */4 * * * /path/to/DhakaCart-03-test/scripts/update-alb-dns-dynamic.sh >> /tmp/alb-dns-update.log 2>&1
```

---

## Configuration Files Updated

- ✅ `docker-compose.yml` - Updated to v1.0.3
- ✅ `k8s/deployments/backend-deployment.yaml` - Updated to v1.0.3
- ✅ `k8s/deployments/frontend-deployment.yaml` - Updated to v1.0.3
- ✅ `k8s/configmaps/app-config.yaml` - Placeholder for dynamic update
- ✅ `backend/server.js` - Added `/api/health` endpoint
- ✅ `terraform/simple-k8s/alb-backend-config.tf` - Health check path fixed

---

## Scripts Created

1. **`scripts/build-and-push-v1.0.3.sh`**
   - Builds and pushes backend and frontend images
   - Tags as v1.0.3 and latest

2. **`scripts/update-alb-dns-dynamic.sh`**
   - Gets ALB DNS from Terraform
   - Updates ConfigMap on Master-1
   - Restarts frontend pods

3. **`scripts/deploy-v1.0.3.sh`**
   - Complete deployment automation
   - Runs build, push, and ALB DNS update

---

**Last Updated**: 2025-12-06  
**Version**: v1.0.3

