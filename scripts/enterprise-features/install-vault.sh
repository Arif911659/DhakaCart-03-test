#!/bin/bash
# Enterprise Feature: HashiCorp Vault Setup
# =========================================
# This script installs Vault and configures Kubernetes Authentication.
# NOTE: Installs in DEV mode for easy demonstration (Auto-unseal).

set -e

echo "🚀 Starting Vault Installation..."

# 0. Check/Install Helm
if ! command -v helm &> /dev/null; then
    echo "⬇️  Helm not found. Installing..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
    echo "✅ Helm installed."
fi

# 1. Add Helm Repo
echo "📦 Adding HashiCorp Helm Repo..."
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 2. Install Vault
echo "🛠️  Installing Vault (Dev Mode)..."
helm install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  --version 0.25.0 \
  -f "$PROJECT_ROOT/k8s/enterprise-features/vault/values.yaml"

# 3. Wait for Vault
echo "⏳ Waiting for Vault to be ready..."
kubectl rollout status deployment/vault-agent-injector -n vault --timeout=120s
# Verify Vault Pod (StatefulSet)
kubectl wait --for=condition=ready pod/vault-0 -n vault --timeout=120s

# 4. Enable Kubernetes Auth
echo "🔑 Configuring Vault Kubernetes Auth..."
kubectl exec -n vault vault-0 -- vault auth enable kubernetes

kubectl exec -n vault vault-0 -- vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

echo "🎉 Vault Setup Complete!"
echo "Next: Create a secret using: kubectl exec -n vault vault-0 -- vault kv put secret/dhakacart db_pass=supersecret"
