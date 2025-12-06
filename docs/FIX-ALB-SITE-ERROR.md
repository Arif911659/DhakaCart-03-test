# 🔧 Fix ALB Site Error - Complete Solution

**Issue**: Browser shows site error when accessing ALB URL  
**Date**: 2025-12-06

---

## Problem Analysis

The main issues identified:

1. **Backend Target Group Health Check Path Mismatch**
   - Target group configured: `/api/health`
   - Backend actual endpoint: `/health`
   - Result: Health checks fail → Targets marked unhealthy → ALB returns 502/503

2. **Backend Missing `/api/health` Endpoint**
   - ALB routes `/api/*` to backend
   - If health check uses `/api/health`, it should exist
   - Currently only `/health` exists

---

## Solutions Applied

### ✅ Solution 1: Fixed Terraform Configuration

**File**: `terraform/simple-k8s/alb-backend-config.tf`

Changed health check path from `/api/health` to `/health`:
```hcl
health_check {
  path = "/health"  # Changed from "/api/health"
  ...
}
```

### ✅ Solution 2: Added `/api/health` Endpoint to Backend

**File**: `backend/server.js`

Added both `/health` and `/api/health` endpoints:
```javascript
app.get('/health', healthCheckHandler);
app.get('/api/health', healthCheckHandler);
```

---

## Step-by-Step Fix Instructions

### Option A: Quick Fix (No Rebuild Required)

This fixes the immediate issue by updating the target group health check:

1. **Update Target Group Health Check Path** (AWS Console):

   - Go to: AWS Console → EC2 → Target Groups
   - Select: `dhakacart-k8s-backend-tg`
   - Click: "Health checks" tab → "Edit"
   - Change Path: `/api/health` → `/health`
   - Click: "Save changes"
   - Wait 1-2 minutes for health checks to pass

2. **Verify Target Health**:

   ```bash
   # On your local machine
   aws elbv2 describe-target-health \
     --target-group-arn "arn:aws:elasticloadbalancing:ap-southeast-1:495599770374:targetgroup/dhakacart-k8s-backend-tg/4714187ef75a5692" \
     --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' \
     --output table
   ```

3. **Test Site**:

   ```bash
   curl http://dhakacart-k8s-alb-1190423189.ap-southeast-1.elb.amazonaws.com/
   curl http://dhakacart-k8s-alb-1190423189.ap-southeast-1.elb.amazonaws.com/api/products
   ```

### Option B: Complete Fix (With Backend Rebuild)

This applies all fixes including the new `/api/health` endpoint:

#### Step 1: Rebuild Backend Docker Image

```bash
# On your local machine
cd backend
docker build -t arifhossaincse22/dhakacart-backend:v1.0.1 .
docker push arifhossaincse22/dhakacart-backend:v1.0.1
```

#### Step 2: Update Backend Deployment

**On Master-1 node:**

```bash
# Update deployment with new image
kubectl set image deployment/dhakacart-backend \
  backend=arifhossaincse22/dhakacart-backend:v1.0.1 \
  -n dhakacart

# OR update deployment.yaml and apply
# Edit: k8s/deployments/backend-deployment.yaml
# Change: image: arifhossaincse22/dhakacart-backend:v1.0.1
kubectl apply -f ~/k8s/deployments/backend-deployment.yaml

# Wait for rollout
kubectl rollout status deployment/dhakacart-backend -n dhakacart

# Verify pods are running
kubectl get pods -n dhakacart
```

#### Step 3: Update Target Group (Re-apply Terraform)

```bash
# On your local machine
cd terraform/simple-k8s
terraform plan  # Review changes
terraform apply  # Apply health check path fix
```

#### Step 4: Wait and Verify

```bash
# Wait 1-2 minutes for health checks
sleep 120

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn "arn:aws:elasticloadbalancing:ap-southeast-1:495599770374:targetgroup/dhakacart-k8s-backend-tg/4714187ef75a5692" \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' \
  --output table

# Test endpoints
curl http://dhakacart-k8s-alb-1190423189.ap-southeast-1.elb.amazonaws.com/
curl http://dhakacart-k8s-alb-1190423189.ap-southeast-1.elb.amazonaws.com/api/health
curl http://dhakacart-k8s-alb-1190423189.ap-southeast-1.elb.amazonaws.com/api/products
```

---

## Automated Fix Scripts

### Diagnostic Script

```bash
./scripts/diagnose-alb-issue.sh
```

This script will:
- Check target group health status
- Verify health check configuration
- Test endpoints from worker nodes
- Test ALB endpoints
- Provide recommendations

### Fix Script

```bash
./scripts/fix-alb-site-error.sh
```

This script will:
- Update target group health check path to `/health`
- Provide instructions for backend rebuild
- Check target group status

---

## Verification Checklist

- [ ] Backend target group health check path is `/health`
- [ ] Backend pods are running: `kubectl get pods -n dhakacart`
- [ ] Target group shows healthy targets
- [ ] Frontend loads: `curl http://LB_DNS/`
- [ ] Backend API works: `curl http://LB_DNS/api/products`
- [ ] Backend health check works: `curl http://LB_DNS/api/health`

---

## Troubleshooting

### Issue: Targets Still Unhealthy After Fix

**Check:**
1. Backend pods are running: `kubectl get pods -n dhakacart`
2. Pods can reach database/redis: `kubectl logs -n dhakacart <backend-pod>`
3. Health endpoint works from pod: `kubectl exec -n dhakacart <backend-pod> -- curl localhost:5000/health`
4. NodePort is accessible: `curl http://<worker-ip>:30081/health`

**Fix:**
- Check pod logs for errors
- Verify ConfigMap and Secrets are correct
- Verify database and redis services are running

### Issue: ALB Returns 502 Bad Gateway

**Check:**
1. Target group has healthy targets
2. Security groups allow traffic on ports 30080/30081
3. ALB listener rules are configured correctly

**Fix:**
- Verify security groups (already configured in terraform)
- Check ALB listener rules in AWS Console

### Issue: Frontend Shows Empty Page

**Check:**
1. Frontend pods are running
2. Frontend service is NodePort type
3. Frontend target group is healthy
4. Browser console for JavaScript errors

**Fix:**
- Check frontend pod logs: `kubectl logs -n dhakacart <frontend-pod>`
- Verify ConfigMap has correct `REACT_APP_API_URL`
- Check browser console for API connection errors

---

## Current Configuration Summary

- **Frontend Service**: NodePort 30080
- **Backend Service**: NodePort 30081
- **Frontend Target Group**: Port 30080, Health check: `/`
- **Backend Target Group**: Port 30081, Health check: `/health`
- **ALB Listener Rules**:
  - Priority 100: `/api*` → Backend Target Group
  - Default: All other paths → Frontend Target Group

---

**Last Updated**: 2025-12-06  
**Status**: Ready for deployment

