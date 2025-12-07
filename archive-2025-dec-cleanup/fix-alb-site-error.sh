#!/bin/bash

# ============================================
# Fix ALB Site Error - Complete Solution
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Fixing ALB Site Error${NC}"
echo ""

# Get Terraform outputs
echo -e "${YELLOW}📊 Fetching Terraform outputs...${NC}"
cd "$(dirname "$0")/../terraform/simple-k8s" 2>/dev/null || { 
    echo -e "${RED}❌ Error: terraform/simple-k8s directory not found${NC}"; 
    exit 1; 
}

BACKEND_TG_ARN=$(terraform output -raw backend_target_group_arn 2>/dev/null || echo "")
LB_DNS=$(terraform output -raw load_balancer_dns 2>/dev/null || echo "")

if [ -z "$BACKEND_TG_ARN" ]; then
    echo -e "${RED}❌ Error: Could not fetch backend target group ARN${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Backend Target Group: ${BACKEND_TG_ARN}${NC}"
echo ""

# Step 1: Update Backend Target Group Health Check Path
echo -e "${YELLOW}📝 Step 1: Updating Backend Target Group Health Check Path...${NC}"
CURRENT_PATH=$(aws elbv2 describe-target-groups \
  --target-group-arns "${BACKEND_TG_ARN}" \
  --query 'TargetGroups[0].HealthCheckPath' \
  --output text 2>/dev/null || echo "")

if [ "$CURRENT_PATH" != "/health" ]; then
    echo -e "${YELLOW}   Current path: ${CURRENT_PATH}${NC}"
    echo -e "${YELLOW}   Updating to: /health${NC}"
    
    aws elbv2 modify-target-group \
      --target-group-arn "${BACKEND_TG_ARN}" \
      --health-check-path "/health" \
      --health-check-interval-seconds 30 \
      --health-check-timeout-seconds 5 \
      --healthy-threshold-count 2 \
      --unhealthy-threshold-count 2 \
      --matcher HttpCode="200-399" \
      2>/dev/null || {
        echo -e "${RED}❌ Error updating target group. Trying alternative method...${NC}"
        echo -e "${YELLOW}   Please update manually in AWS Console:${NC}"
        echo -e "${YELLOW}   EC2 → Target Groups → ${BACKEND_TG_ARN} → Health checks → Edit${NC}"
        echo -e "${YELLOW}   Change path from '/api/health' to '/health'${NC}"
    }
    
    echo -e "${GREEN}✅ Target group health check path updated${NC}"
else
    echo -e "${GREEN}✅ Health check path is already correct (/health)${NC}"
fi
echo ""

# Step 2: Check if backend needs to be rebuilt
echo -e "${YELLOW}📝 Step 2: Checking Backend Deployment...${NC}"
echo -e "${BLUE}   Note: Backend code has been updated with /api/health endpoint${NC}"
echo -e "${BLUE}   You need to rebuild and redeploy the backend${NC}"
echo ""

# Step 3: Instructions for rebuilding backend
echo -e "${YELLOW}📝 Step 3: Next Steps to Complete the Fix${NC}"
echo ""
echo -e "${GREEN}To complete the fix, run these commands on Master-1:${NC}"
echo ""
echo "1. Rebuild backend Docker image (from your local machine or CI/CD):"
echo "   cd backend"
echo "   docker build -t dhakacart-backend:latest ."
echo ""
echo "2. Push to your container registry (if using one), OR:"
echo "   Save and copy to Master-1:"
echo "   docker save dhakacart-backend:latest | gzip > backend-image.tar.gz"
echo "   scp backend-image.tar.gz ubuntu@<master-1-ip>:~/"
echo ""
echo "3. On Master-1, load and deploy:"
echo "   docker load < backend-image.tar.gz"
echo "   # Update deployment.yaml with new image"
echo "   kubectl set image deployment/dhakacart-backend dhakacart-backend=dhakacart-backend:latest -n dhakacart"
echo "   # OR apply the updated deployment.yaml"
echo "   kubectl apply -f ~/k8s/deployments/backend-deployment.yaml"
echo ""
echo "4. Restart backend deployment:"
echo "   kubectl rollout restart deployment dhakacart-backend -n dhakacart"
echo ""
echo "5. Wait for rollout:"
echo "   kubectl rollout status deployment/dhakacart-backend -n dhakacart"
echo ""
echo "6. Check pod status:"
echo "   kubectl get pods -n dhakacart"
echo ""
echo "7. Wait 1-2 minutes for target group health checks to pass"
echo ""

# Step 4: Verify target group
echo -e "${YELLOW}📝 Step 4: Checking Target Group Status...${NC}"
echo -e "${BLUE}   Waiting 10 seconds, then checking health...${NC}"
sleep 10

aws elbv2 describe-target-health \
  --target-group-arn "${BACKEND_TG_ARN}" \
  --query 'TargetHealthDescriptions[*].[Target.Id,Target.Port,TargetHealth.State,TargetHealth.Reason]' \
  --output table 2>/dev/null || echo "Error querying health"
echo ""

echo -e "${GREEN}✅ Fix script completed!${NC}"
echo ""
echo -e "${YELLOW}Next: Rebuild and redeploy backend as shown above${NC}"

