#!/bin/bash

##############################################
# DhakaCart 4-Hour Deployment Automation
# Complete infrastructure to production in one script
##############################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  DhakaCart 4-Hour Full Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "⏱️  Target: Complete deployment in <4 hours"
echo "📍 Starting at: $(date '+%H:%M:%S')"
echo ""

# Step 1: Infrastructure (Terraform)
echo -e "${YELLOW}[1/7] 🏗️  Deploying Infrastructure with Terraform...${NC}"
cd "$PROJECT_ROOT/terraform/simple-k8s"

if [ ! -f "dhakacart-k8s-key.pem" ]; then
    echo -e "${RED}❌ SSH key not found!${NC}"
    exit 1
fi

terraform init -upgrade
terraform apply -auto-approve

echo -e "${GREEN}✅ Infrastructure deployed${NC}"
echo ""

# Step 2: Extract configuration
echo -e "${YELLOW}[2/7] 📋 Extracting configuration...${NC}"
source "$PROJECT_ROOT/scripts/load-infrastructure-config.sh"

echo "  Bastion IP: $BASTION_IP"
echo "  Master-1 IP: ${MASTER_IPS[0]}"
echo "  ALB DNS: $ALB_DNS"
echo -e "${GREEN}✅ Configuration loaded${NC}"
echo ""

# Step 3: Update node configuration scripts
echo -e "${YELLOW}[3/7] 📝 Updating node configuration scripts...${NC}"
cd "$PROJECT_ROOT/terraform/simple-k8s/nodes-config-steps"
./extract-terraform-outputs.sh
./generate-scripts.sh
echo -e "${GREEN}✅ Scripts generated${NC}"
echo ""

# Step 4: Upload to Bastion and configure nodes
echo -e "${YELLOW}[4/7] 🚀 Configuring Kubernetes nodes...${NC}"
./upload-to-bastion.sh

echo "⏳ Waiting 30s for Bastion readiness..."
sleep 30

# Configure Master-1
echo "  Configuring Master-1..."
ssh -i ../dhakacart-k8s-key.pem -o StrictHostKeyChecking=no ubuntu@${BASTION_IP} \
  "ssh -i ~/.ssh/dhakacart-k8s-key.pem -o StrictHostKeyChecking=no ubuntu@${MASTER_IPS[0]} \
   'bash ~/nodes-config/master-1.sh'" &

MASTER1_PID=$!
echo "  Master-1 configuration started (PID: $MASTER1_PID)"

# Wait for Master-1 to complete
wait $MASTER1_PID
echo -e "${GREEN}✅ Master-1 configured${NC}"

# Get join tokens
echo "  Extracting join tokens..."

# Join command for control plane (Master-2)
CP_JOIN_COMMAND=$(ssh -i ../dhakacart-k8s-key.pem ubuntu@${BASTION_IP} \
  "ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@${MASTER_IPS[0]} \
   'kubeadm token create --print-join-command --certificate-key \$(kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -1)'")

# Join command for workers
WORKER_JOIN_COMMAND=$(ssh -i ../dhakacart-k8s-key.pem ubuntu@${BASTION_IP} \
  "ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@${MASTER_IPS[0]} \
   'kubeadm token create --print-join-command'")

# Join Master-2 to control plane
if [ ${#MASTER_IPS[@]} -gt 1 ]; then
    echo "  Joining Master-2 to control plane..."
    ssh -i ../dhakacart-k8s-key.pem ubuntu@${BASTION_IP} \
      "ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@${MASTER_IPS[1]} \
       'bash ~/nodes-config/master-2-prereq.sh && sudo $CP_JOIN_COMMAND --control-plane'" &
    MASTER2_PID=$!
    wait $MASTER2_PID
    echo -e "${GREEN}✅ Master-2 joined${NC}"
fi

# Join Workers in parallel
echo "  Joining ${#WORKER_IPS[@]} Worker nodes..."
for worker_ip in "${WORKER_IPS[@]}"; do
    echo "    Joining worker: $worker_ip"
    ssh -i ../dhakacart-k8s-key.pem ubuntu@${BASTION_IP} \
      "ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@$worker_ip \
       'bash ~/nodes-config/workers-prereq.sh && sudo $WORKER_JOIN_COMMAND'" &
done

wait
echo -e "${GREEN}✅ All ${#WORKER_IPS[@]} workers joined${NC}"
echo ""

# Step 5: Deploy Application
echo -e "${YELLOW}[5/7] 📦 Deploying Application...${NC}"
cd "$PROJECT_ROOT"

# Update ConfigMap with ALB DNS
sed -i "s|REACT_APP_API_URL:.*|REACT_APP_API_URL: http://${ALB_DNS}/api|" k8s/configmaps/app-config.yaml

# Sync to Master-1
./scripts/k8s-deployment/sync-k8s-to-master1.sh

# Deploy
ssh -i terraform/simple-k8s/dhakacart-k8s-key.pem ubuntu@${BASTION_IP} \
  "ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@${MASTER_IPS[0]} \
   'cd ~/k8s && ./deploy-prod.sh'"

echo -e "${GREEN}✅ Application deployed${NC}"
echo ""

# Step 6: Register ALB Targets
echo -e "${YELLOW}[6/7] 🎯 Registering ALB targets...${NC}"
cd "$PROJECT_ROOT/terraform/simple-k8s"
./register-workers-to-alb.sh

echo -e "${GREEN}✅ ALB targets registered${NC}"
echo ""

# Step 7: Verification
echo -e "${YELLOW}[7/7] ✅ Verification...${NC}"

echo "⏳ Waiting for pods to be ready (60s)..."
sleep 60

ssh -i dhakacart-k8s-key.pem ubuntu@${BASTION_IP} \
  "ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@${MASTER_IPS[0]} \
   'kubectl get nodes && kubectl get pods -n dhakacart && kubectl get pods -n monitoring'"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✅ Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "⏱️  Completed at: $(date '+%H:%M:%S')"
echo ""
echo -e "${BLUE}🌐 Access URLs:${NC}"
echo "  Frontend: http://${ALB_DNS}"
echo "  Grafana:  http://${ALB_DNS}/grafana/"
echo "  Login:    admin / dhakacart123"
echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "  1. Test frontend: curl -I http://${ALB_DNS}"
echo "  2. Access Grafana and import dashboard 1860"
echo "  3. Run security hardening: ./scripts/security/apply-security-hardening.sh"
echo ""
