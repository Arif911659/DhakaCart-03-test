#!/bin/bash

# Fetch Kubeconfig Script
# Retrieves ~/.kube/config from Master-1 via Bastion

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source config loader
if [ -f "$SCRIPT_DIR/load-infrastructure-config.sh" ]; then
    source "$SCRIPT_DIR/load-infrastructure-config.sh"
else
    echo "Error: Config loader not found at $SCRIPT_DIR/load-infrastructure-config.sh"
    exit 1
fi

echo "Fetching kubeconfig from Master-1 ($MASTER1_IP) via Bastion ($BASTION_IP)..."

# SSH Command to fetch config
# Uses -o ProxyCommand or -J (JumpHost) depending on SSH version, but -J is standard now.
# We use the loaded SSH_KEY_PATH

ssh -i "$SSH_KEY_PATH" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ProxyCommand="ssh -i \"$SSH_KEY_PATH\" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ubuntu@$BASTION_IP" \
    ubuntu@$MASTER1_IP "sudo cat /etc/kubernetes/admin.conf || cat ~/.kube/config" > "$PROJECT_ROOT/kubeconfig_fetched"

if [ -s "$PROJECT_ROOT/kubeconfig_fetched" ]; then
    echo ""
    echo "✅ Kubeconfig successfully fetched and saved to: $PROJECT_ROOT/kubeconfig_fetched"
    echo ""
    echo "👇 COPY THE CONTENT BELOW FOR GITHUB SECRETS 👇"
    echo "==================================================="
    cat "$PROJECT_ROOT/kubeconfig_fetched"
    echo "==================================================="
    echo "☝️  COPY THE CONTENT ABOVE ☝️"
    echo ""
    echo "Instructions:"
    echo "1. Go to GitHub Repo -> Settings -> Secrets and variables -> Actions"
    echo "2. Create New Repository Secret"
    echo "3. Name: KUBECONFIG"
    echo "4. Paste the content above"
else
    echo "❌ Failed to fetch kubeconfig. File is empty."
    exit 1
fi
