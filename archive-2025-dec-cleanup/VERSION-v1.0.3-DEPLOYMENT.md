# 🚀 Version 1.0.3 Deployment Guide

**Date**: 2025-12-06  
**Version**: v1.0.3  
**Changes**: Added `/api/health` endpoint, Dynamic ALB DNS support, Health check fixes

---

## Quick Deployment Commands

### Option 1: Automated Deployment (Recommended)

```bash
# Complete automated deployment
./scripts/deploy-v1.0.3.sh
```

### Option 2: Step by Step

```bash
# Step 1: Build and push images
./scripts/build-and-push-v1.0.3.sh

# Step 2: Update ALB DNS (dynamic)
./scripts/update-alb-dns-dynamic.sh

# Step 3: Deploy to Kubernetes (on Master-1)
ssh -i terraform/simple-k8s/dhakacart-k8s-key.pem ubuntu@54.169.237.62
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@10.0.10.128
kubectl apply -f ~/k8s/deployments/backend-deployment.yaml
kubectl apply -f ~/k8s/deployments/frontend-deployment.yaml
```

---

## What's New in v1.0.3

### Backend Changes
- ✅ Added `/api/health` endpoint (for ALB health checks)
- ✅ Fixed health check handler for both `/health` and `/api/health`

### Infrastructure Changes
- ✅ Fixed backend target group health check path (`/health`)
- ✅ Dynamic ALB DNS update script for LAB environments
- ✅ Automated deployment scripts

### Configuration Updates
- ✅ All images updated to v1.0.3
- ✅ ConfigMap template updated for dynamic ALB DNS

---

## Files Updated

### Docker Images
- `docker-compose.yml` → v1.0.3

### Kubernetes Deployments
- `k8s/deployments/backend-deployment.yaml` → v1.0.3
- `k8s/deployments/frontend-deployment.yaml` → v1.0.3

### Configuration
- `k8s/configmaps/app-config.yaml` → Dynamic ALB DNS placeholder
- `terraform/simple-k8s/alb-backend-config.tf` → Health check path fixed
- `backend/server.js` → Added `/api/health` endpoint

### Scripts
- ✅ `scripts/build-and-push-v1.0.3.sh` - Build and push images
- ✅ `scripts/update-alb-dns-dynamic.sh` - Dynamic ALB DNS update
- ✅ `scripts/deploy-v1.0.3.sh` - Complete deployment automation

---

## Verification Steps

### 1. Verify Images

```bash
# Check images on Docker Hub
docker pull arifhossaincse22/dhakacart-backend:v1.0.3
docker pull arifhossaincse22/dhakacart-frontend:v1.0.3
```

### 2. Verify ALB DNS

```bash
cd terraform/simple-k8s
terraform output load_balancer_dns
```

### 3. Verify ConfigMap

```bash
# On Master-1
kubectl get configmap dhakacart-config -n dhakacart -o yaml | grep REACT_APP_API_URL
```

### 4. Verify Pods

```bash
# On Master-1
kubectl get pods -n dhakacart
kubectl get deployments -n dhakacart
```

### 5. Verify Services

```bash
# On Master-1
kubectl get svc -n dhakacart
kubectl describe svc dhakacart-backend-service -n dhakacart | grep NodePort
kubectl describe svc dhakacart-frontend-service -n dhakacart | grep NodePort
```

### 6. Test Site

```bash
# Get ALB DNS
ALB_DNS=$(cd terraform/simple-k8s && terraform output -raw load_balancer_dns)

# Test endpoints
curl http://$ALB_DNS/
curl http://$ALB_DNS/api/health
curl http://$ALB_DNS/api/products
```

---

## Troubleshooting

### Issue: Images not found

**Solution:**
```bash
# Rebuild and push
./scripts/build-and-push-v1.0.3.sh
```

### Issue: ALB DNS not updated

**Solution:**
```bash
# Update manually
./scripts/update-alb-dns-dynamic.sh

# Or manually on Master-1
kubectl patch configmap dhakacart-config -n dhakacart \
  --patch '{"data":{"REACT_APP_API_URL":"http://NEW_ALB_DNS/api"}}'
kubectl rollout restart deployment dhakacart-frontend -n dhakacart
```

### Issue: Pods not starting

**Solution:**
```bash
# Check pod logs
kubectl logs -n dhakacart -l app=dhakacart-backend
kubectl logs -n dhakacart -l app=dhakacart-frontend

# Check events
kubectl get events -n dhakacart --sort-by='.lastTimestamp'
```

---

## Rollback (if needed)

```bash
# Rollback to previous version
kubectl set image deployment/dhakacart-backend \
  backend=arifhossaincse22/dhakacart-backend:v1.0.2 \
  -n dhakacart

kubectl set image deployment/dhakacart-frontend \
  frontend=arifhossaincse22/dhakacart-frontend:v1.0.2 \
  -n dhakacart

kubectl rollout status deployment/dhakacart-backend -n dhakacart
kubectl rollout status deployment/dhakacart-frontend -n dhakacart
```

---

## Next Steps

1. ✅ Build and push images
2. ✅ Update ALB DNS
3. ✅ Deploy to Kubernetes
4. ✅ Verify deployment
5. ✅ Test site functionality

---

**For detailed documentation, see:**
- `docs/DYNAMIC-ALB-DNS-UPDATE.md` - Dynamic ALB DNS update guide
- `docs/FIX-ALB-SITE-ERROR.md` - ALB site error troubleshooting

