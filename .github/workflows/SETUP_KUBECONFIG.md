# 🔑 KUBECONFIG Setup Guide

This guide explains how to get your Kubernetes Cluster configuration and add it to GitHub Secrets so that the CD pipeline can deploy your application.

## Step 1: Get the Kubeconfig

Since you are using a custom Terraform setup, your Kubeconfig file is located inside your **Master Node**. We have created a helper script to get it for you easily.

1. Open your terminal in the project root.
2. Run the fetch script:
   ```bash
   ./scripts/fetch-kubeconfig.sh
   ```

3. The script will:
   - Connect to your Bastion host.
   - Jump to Master-1.
   - Read the configuration file (`admin.conf`).
   - Show the content on your screen AND save it to a file named `kubeconfig_fetched`.

## Step 2: Add to GitHub Secrets

1. **Copy the content** displayed by the script (starts with `apiVersion: v1`...).
2. Go to your GitHub Repository.
3. Click on **Settings** (top right tab).
4. On the left sidebar, find **Secrets and variables** and click **Actions**.
5. Click the green button **New repository secret**.
6. Fill in the details:
   - **Name**: `KUBECONFIG`
   - **Secret**: (Paste the copied content here)
7. Click **Add secret**.

## Step 3: Verify

Once added, your next deployment (via `git push` or Manual Release) will automatically pick up this secret and be able to deploy to your cluster!

> **Note:** This `KUBECONFIG` gives full admin access to your cluster. Keep it safe and never share it publicly.
