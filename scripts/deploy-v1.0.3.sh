#!/bin/bash

# ============================================
# Complete Deployment Script v1.0.3
# ============================================
# This script automates the complete deployment process:
# 1. Build and push Docker images
# 2. Update ALB DNS dynamically
# 3. Deploy to Kubernetes
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}Complete Deployment v1.0.3${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

# Step 1: Build and Push Images
echo -e "${YELLOW}Step 1/3: Building and Pushing Docker Images...${NC}"
echo ""
"$SCRIPT_DIR/build-and-push-v1.0.3.sh"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build and push failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Step 1 Complete!${NC}"
echo ""

# Step 2: Update ALB DNS
echo -e "${YELLOW}Step 2/3: Updating ALB DNS in ConfigMap...${NC}"
echo ""
"$SCRIPT_DIR/update-alb-dns-dynamic.sh"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ALB DNS update failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Step 2 Complete!${NC}"
echo ""

# Step 3: Deploy to Kubernetes (instructions)
echo -e "${YELLOW}Step 3/3: Deploy to Kubernetes${NC}"
echo ""
echo -e "${BLUE}Run these commands on Master-1:${NC}"
echo ""
echo "  ssh -i terraform/simple-k8s/dhakacart-k8s-key.pem ubuntu@54.169.237.62"
echo "  ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@10.0.10.128"
echo ""
echo "  # Apply deployments"
echo "  kubectl apply -f ~/k8s/deployments/backend-deployment.yaml"
echo "  kubectl apply -f ~/k8s/deployments/frontend-deployment.yaml"
echo ""
echo "  # Wait for rollout"
echo "  kubectl rollout status deployment/dhakacart-backend -n dhakacart"
echo "  kubectl rollout status deployment/dhakacart-frontend -n dhakacart"
echo ""
echo "  # Verify pods"
echo "  kubectl get pods -n dhakacart"
echo ""

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}✅ Deployment Process Complete!${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""
echo -e "${GREEN}Summary:${NC}"
echo "  ✅ Images built and pushed: v1.0.3"
echo "  ✅ ConfigMap updated with ALB DNS"
echo "  ⏳ Kubernetes deployment pending (run commands above)"
echo ""

