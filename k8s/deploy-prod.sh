#!/bin/bash

# ==============================================================================
# DhakaCart Production Deployment Script
# ==============================================================================
# This script automates the deployment of DhakaCart to a Kubernetes cluster.
# It handles:
# 1. Applying base resources (Namespace, Secrets, Volumes)
# 2. Applying ConfigMaps
# 3. auto-updating the ConfigMap with the correct ALB DNS
# 4. Applying Deployments and Services
# 5. Applying Ingress
# 6. Restarting deployments to ensure new config is picked up
# ==============================================================================

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}🚀 Starting DhakaCart Deployment...${NC}"
echo ""

# 1. Base Resources
echo -e "${YELLOW}📦 Applying Base Resources...${NC}"
kubectl apply -f "$SCRIPT_DIR/namespace.yaml"
kubectl apply -f "$SCRIPT_DIR/secrets/"
kubectl apply -f "$SCRIPT_DIR/volumes/"
echo -e "${GREEN}✅ Base resources applied.${NC}"
echo ""

# 2. ConfigMaps
echo -e "${YELLOW}📝 Applying ConfigMaps...${NC}"
kubectl apply -f "$SCRIPT_DIR/configmaps/"
echo -e "${GREEN}✅ Base ConfigMaps applied.${NC}"
echo ""

# 3. Update ConfigMap with ALB DNS
echo -e "${YELLOW}🔄 Updating ConfigMap with ALB DNS...${NC}"
if [ -f "$SCRIPT_DIR/update-configmap-with-alb-dns.sh" ]; then
    chmod +x "$SCRIPT_DIR/update-configmap-with-alb-dns.sh"
    # We run this in a subshell or just execute it. It internally calls kubectl apply.
    "$SCRIPT_DIR/update-configmap-with-alb-dns.sh"
else
    echo -e "${RED}⚠️  Warning: update-configmap-with-alb-dns.sh not found! Skipping auto-update.${NC}"
    echo "Make sure REACT_APP_API_URL is set correctly in configmaps/app-config.yaml"
fi
echo ""

# 4. Deployments and Services
echo -e "${YELLOW}🚀 Applying Deployments and Services...${NC}"
kubectl apply -f "$SCRIPT_DIR/deployments/"
kubectl apply -f "$SCRIPT_DIR/services/"
echo -e "${GREEN}✅ Deployments and Services applied.${NC}"
echo ""

# 5. Ingress
echo -e "${YELLOW}🌐 Applying Ingress...${NC}"
if [ -f "$SCRIPT_DIR/ingress/ingress-alb.yaml" ]; then
    kubectl apply -f "$SCRIPT_DIR/ingress/ingress-alb.yaml"
    echo -e "${GREEN}✅ ALB Ingress applied.${NC}"
else
    echo -e "${YELLOW}ℹ️  ingress-alb.yaml not found, applying default ingress...${NC}"
    kubectl apply -f "$SCRIPT_DIR/ingress/"
fi
echo ""

# 6. Database Check
echo -e "${YELLOW}💾 Checking Database Status...${NC}"
# We can't easily check row count here without knowing pod name, but we can remind the user.
echo -e "${YELLOW}⚠️  REMINDER: If this is a fresh install, don't forget to seed the database!${NC}"
echo "Run: kubectl exec -i -n dhakacart deployment/dhakacart-db -- psql -U dhakacart -d dhakacart_db < database/init.sql"
echo ""

# 7. Restart for Consistency
echo -e "${YELLOW}🔄 Restarting Frontend and Backend to ensure config pickup...${NC}"
kubectl rollout restart deployment/dhakacart-frontend -n dhakacart
kubectl rollout restart deployment/dhakacart-backend -n dhakacart
echo -e "${GREEN}✅ Rollout restart triggered.${NC}"
echo ""

echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo -e "Check status with: ${YELLOW}kubectl get all -n dhakacart${NC}"
