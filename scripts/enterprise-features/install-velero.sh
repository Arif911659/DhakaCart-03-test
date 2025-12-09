#!/bin/bash
# Enterprise Feature: Velero Automated Backup Setup
# =================================================
# This script installs Velero in the Kubernetes cluster and configures it with AWS S3.
# Prerequisites: AWS Credentials must be set.

set -e

# Configuration
BUCKET_NAME="dhakacart-backups-$(date +%Y%m%d)" # Unique bucket name
REGION="us-east-1"
CLUSTER_NAME="dhakacart-cluster"

echo "🚀 Starting Velero Setup for $CLUSTER_NAME..."

# 1. Check Tools
if ! command -v velero &> /dev/null; then
    echo "⬇️  Velero CLI not found. Downloading..."
    wget https://github.com/vmware-tanzu/velero/releases/download/v1.12.0/velero-v1.12.0-linux-amd64.tar.gz
    tar -zxvf velero-v1.12.0-linux-amd64.tar.gz
    sudo mv velero-v1.12.0-linux-amd64/velero /usr/local/bin/
    rm -rf velero-v1.12.0-linux-amd64*
    echo "✅ Velero CLI installed."
fi

# 2. Setup AWS S3 Bucket (if using Terraform, this skip is fine, but good for standalone)
echo "📦 Checking S3 Bucket: $BUCKET_NAME..."
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3 mb "s3://$BUCKET_NAME" --region $REGION
    echo "✅ Created S3 Bucket: $BUCKET_NAME"
else
    echo "✅ S3 Bucket exists."
fi

# 3. Create IAM User for Velero (Simplified for script)
# NOTE: In production, use OIDC/IRSA. Here using Access Keys for simplicity.
echo "🔑 Ensuring IAM permissions..."
# (Skipping explicit IAM creation to prevent script complexity errors - assuming Env Vars exist)
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "❌ Error: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be exported."
    exit 1
fi

# Create credentials file
cat > credentials-velero <<EOF
[default]
aws_access_key_id=$AWS_ACCESS_KEY_ID
aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
EOF

# 4. Install Velero Server
echo "🛠️  Installing Velero Server..."
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.8.0 \
    --bucket $BUCKET_NAME \
    --backup-location-config region=$REGION \
    --snapshot-location-config region=$REGION \
    --secret-file ./credentials-velero \
    --use-node-agent

# 5. Apply Schedule
echo "📅 Applying Daily Backup Schedule..."
kubectl apply -f ../../k8s/enterprise-features/velero/daily-backup.yaml

echo "🎉 Velero Setup Complete!"
echo "Test with: velero backup create manual-test"
rm credentials-velero
