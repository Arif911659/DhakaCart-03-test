#!/bin/bash

# ============================================
# ALB Site Error Diagnostic and Fix Script
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 DhakaCart ALB Site Error Diagnostic Tool${NC}"
echo ""

# Get Terraform outputs
echo -e "${YELLOW}📊 Fetching Terraform outputs...${NC}"
cd terraform/simple-k8s 2>/dev/null || { echo -e "${RED}❌ Error: terraform/simple-k8s directory not found${NC}"; exit 1; }

FRONTEND_TG_ARN=$(terraform output -raw frontend_target_group_arn 2>/dev/null || echo "")
BACKEND_TG_ARN=$(terraform output -raw backend_target_group_arn 2>/dev/null || echo "")
LB_DNS=$(terraform output -raw load_balancer_dns 2>/dev/null || echo "")
WORKER_IPS=$(terraform output -json worker_private_ips 2>/dev/null | jq -r '.[]' || echo "")

if [ -z "$FRONTEND_TG_ARN" ] || [ -z "$BACKEND_TG_ARN" ] || [ -z "$LB_DNS" ]; then
    echo -e "${RED}❌ Error: Could not fetch Terraform outputs${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend Target Group: ${FRONTEND_TG_ARN}${NC}"
echo -e "${GREEN}✅ Backend Target Group: ${BACKEND_TG_ARN}${NC}"
echo -e "${GREEN}✅ Load Balancer DNS: ${LB_DNS}${NC}"
echo ""

# Check Target Group Health
echo -e "${YELLOW}🏥 Checking Frontend Target Group Health...${NC}"
FRONTEND_HEALTH=$(aws elbv2 describe-target-health \
  --target-group-arn "${FRONTEND_TG_ARN}" \
  --query 'TargetHealthDescriptions[*].[Target.Id,Target.Port,TargetHealth.State,TargetHealth.Reason]' \
  --output table 2>/dev/null || echo "Error querying health")

echo "$FRONTEND_HEALTH"
echo ""

echo -e "${YELLOW}🏥 Checking Backend Target Group Health...${NC}"
BACKEND_HEALTH=$(aws elbv2 describe-target-health \
  --target-group-arn "${BACKEND_TG_ARN}" \
  --query 'TargetHealthDescriptions[*].[Target.Id,Target.Port,TargetHealth.State,TargetHealth.Reason]' \
  --output table 2>/dev/null || echo "Error querying health")

echo "$BACKEND_HEALTH"
echo ""

# Check Target Group Health Check Configuration
echo -e "${YELLOW}🔧 Checking Target Group Health Check Configuration...${NC}"
echo -e "${BLUE}Frontend Target Group Health Check:${NC}"
aws elbv2 describe-target-groups \
  --target-group-arns "${FRONTEND_TG_ARN}" \
  --query 'TargetGroups[0].HealthCheckPath' \
  --output text 2>/dev/null || echo "Error"

echo -e "${BLUE}Backend Target Group Health Check:${NC}"
aws elbv2 describe-target-groups \
  --target-group-arns "${BACKEND_TG_ARN}" \
  --query 'TargetGroups[0].HealthCheckPath' \
  --output text 2>/dev/null || echo "Error"
echo ""

# Check ALB Listener Rules
echo -e "${YELLOW}🔧 Checking ALB Listener Rules...${NC}"
LB_ARN=$(aws elbv2 describe-load-balancers \
  --names "dhakacart-k8s-alb" \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text 2>/dev/null || echo "")

if [ -n "$LB_ARN" ]; then
    LISTENER_ARN=$(aws elbv2 describe-listeners \
      --load-balancer-arn "${LB_ARN}" \
      --query 'Listeners[?Port==`80`].ListenerArn' \
      --output text 2>/dev/null || echo "")
    
    if [ -n "$LISTENER_ARN" ]; then
        echo -e "${BLUE}Listener Rules:${NC}"
        aws elbv2 describe-rules \
          --listener-arn "${LISTENER_ARN}" \
          --query 'Rules[*].[Priority,Conditions[0].Values[0],Actions[0].TargetGroupArn]' \
          --output table 2>/dev/null || echo "Error"
    fi
fi
echo ""

# Test Backend Health Endpoint from Worker Nodes
echo -e "${YELLOW}🧪 Testing Backend Health Endpoints...${NC}"
for WORKER_IP in $WORKER_IPS; do
    echo -e "${BLUE}Testing http://${WORKER_IP}:30081/health${NC}"
    curl -s -o /dev/null -w "  Status: %{http_code}\n" \
      --connect-timeout 5 \
      "http://${WORKER_IP}:30081/health" || echo -e "  ${RED}Connection failed${NC}"
    
    echo -e "${BLUE}Testing http://${WORKER_IP}:30081/api/health${NC}"
    curl -s -o /dev/null -w "  Status: %{http_code}\n" \
      --connect-timeout 5 \
      "http://${WORKER_IP}:30081/api/health" || echo -e "  ${RED}Connection failed${NC}"
done
echo ""

# Test Frontend from Worker Nodes
echo -e "${YELLOW}🧪 Testing Frontend from Worker Nodes...${NC}"
for WORKER_IP in $WORKER_IPS; do
    echo -e "${BLUE}Testing http://${WORKER_IP}:30080/${NC}"
    curl -s -o /dev/null -w "  Status: %{http_code}\n" \
      --connect-timeout 5 \
      "http://${WORKER_IP}:30080/" || echo -e "  ${RED}Connection failed${NC}"
done
echo ""

# Test ALB Endpoints
echo -e "${YELLOW}🧪 Testing ALB Endpoints...${NC}"
echo -e "${BLUE}Testing http://${LB_DNS}/${NC}"
curl -s -o /dev/null -w "  Status: %{http_code}\n" \
  --connect-timeout 10 \
  "http://${LB_DNS}/" || echo -e "  ${RED}Connection failed${NC}"

echo -e "${BLUE}Testing http://${LB_DNS}/api/health${NC}"
curl -s -o /dev/null -w "  Status: %{http_code}\n" \
  --connect-timeout 10 \
  "http://${LB_DNS}/api/health" || echo -e "  ${RED}Connection failed${NC}"

echo -e "${BLUE}Testing http://${LB_DNS}/api/products${NC}"
curl -s -o /dev/null -w "  Status: %{http_code}\n" \
  --connect-timeout 10 \
  "http://${LB_DNS}/api/products" || echo -e "  ${RED}Connection failed${NC}"
echo ""

# Summary and Recommendations
echo -e "${YELLOW}📋 Summary and Recommendations:${NC}"
echo ""
echo "1. If Backend Target Group health check path is '/api/health':"
echo "   → Update it to '/health' in AWS Console or re-apply terraform"
echo ""
echo "2. If targets are unhealthy:"
echo "   → Check if pods are running: kubectl get pods -n dhakacart"
echo "   → Rebuild backend with new /api/health endpoint"
echo "   → Redeploy backend: kubectl rollout restart deployment dhakacart-backend -n dhakacart"
echo ""
echo "3. If ALB returns 502/503:"
echo "   → Check target group health status (should be 'healthy')"
echo "   → Verify security groups allow traffic on ports 30080/30081"
echo ""
echo "4. To fix backend health endpoint:"
echo "   → Rebuild backend Docker image"
echo "   → Update deployment in Kubernetes"
echo ""

echo -e "${GREEN}✅ Diagnostic complete!${NC}"

