#!/bin/bash
# Enterprise Feature: Cert-Manager (HTTPS) Setup
# ==============================================
# This script installs Cert-Manager and configures Let's Encrypt.

set -e

echo "🚀 Starting Cert-Manager Installation..."

# 1. Add Helm Repo
echo "📦 Adding Jetstack Helm Repo..."
helm repo add jetstack https://charts.jetstack.io
helm repo update

# 2. Install Cert-Manager
echo "🛠️  Installing Cert-Manager..."
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0 \
  --set installCRDs=true

# 3. Wait for Pods
echo "⏳ Waiting for Cert-Manager to be ready..."
kubectl rollout status deployment/cert-manager -n cert-manager --timeout=120s
kubectl rollout status deployment/cert-manager-webhook -n cert-manager --timeout=120s

# 4. Apply ClusterIssuer
echo "📝 Applying Let's Encrypt ClusterIssuer..."
kubectl apply -f ../../k8s/enterprise-features/cert-manager/cluster-issuer.yaml

echo "🎉 Cert-Manager Setup Complete!"
echo "Next: Add 'cert-manager.io/cluster-issuer: letsencrypt-prod' to your Ingress."
