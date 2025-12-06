#!/bin/bash

# ============================================
# Build and Push Docker Images v1.0.3
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
VERSION="v1.0.3"
BACKEND_IMAGE="arifhossaincse22/dhakacart-backend"
FRONTEND_IMAGE="arifhossaincse22/dhakacart-frontend"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}Build and Push Docker Images v1.0.3${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker is not running!${NC}"
    exit 1
fi

# Check if logged in to DockerHub
echo -e "${YELLOW}🔐 Checking Docker Hub authentication...${NC}"
if ! docker info | grep -q "Username"; then
    echo -e "${YELLOW}⚠️  Not logged in to Docker Hub${NC}"
    echo -e "${YELLOW}Please login: docker login${NC}"
    read -p "Press Enter after logging in, or Ctrl+C to cancel..."
fi
echo ""

# Build Backend
echo -e "${GREEN}🔨 Building Backend Image...${NC}"
cd "$PROJECT_ROOT/backend"
echo "Building: ${BACKEND_IMAGE}:${VERSION}"

docker build \
  --target production \
  -t ${BACKEND_IMAGE}:${VERSION} \
  -t ${BACKEND_IMAGE}:latest \
  .

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Backend build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Backend build successful!${NC}"
echo ""

# Push Backend
echo -e "${GREEN}📤 Pushing Backend Image to Docker Hub...${NC}"
docker push ${BACKEND_IMAGE}:${VERSION}
docker push ${BACKEND_IMAGE}:latest

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Backend push failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Backend pushed successfully!${NC}"
echo ""

# Build Frontend
echo -e "${GREEN}🔨 Building Frontend Image...${NC}"
cd "$PROJECT_ROOT/frontend"
echo "Building: ${FRONTEND_IMAGE}:${VERSION}"

docker build \
  --target production \
  -t ${FRONTEND_IMAGE}:${VERSION} \
  -t ${FRONTEND_IMAGE}:latest \
  .

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Frontend build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend build successful!${NC}"
echo ""

# Push Frontend
echo -e "${GREEN}📤 Pushing Frontend Image to Docker Hub...${NC}"
docker push ${FRONTEND_IMAGE}:${VERSION}
docker push ${FRONTEND_IMAGE}:latest

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Frontend push failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend pushed successfully!${NC}"
echo ""

# Summary
echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}✅ Build and Push Complete!${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""
echo -e "${GREEN}Images pushed:${NC}"
echo "  - ${BACKEND_IMAGE}:${VERSION}"
echo "  - ${BACKEND_IMAGE}:latest"
echo "  - ${FRONTEND_IMAGE}:${VERSION}"
echo "  - ${FRONTEND_IMAGE}:latest"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Update ConfigMap with new ALB DNS: ./scripts/update-alb-dns-dynamic.sh"
echo "  2. Deploy to Kubernetes: kubectl apply -f k8s/deployments/"
echo ""

