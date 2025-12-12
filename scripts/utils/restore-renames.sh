#!/bin/bash
# RESTORE SCRIPT (Backup of previous state)
# Run this to undo the "deploy-full-stack" renaming

set -e

echo "Restoring original file names..."

# 1. Restore Script
if [ -f "scripts/deploy-full-stack.sh" ]; then
    mv scripts/deploy-full-stack.sh scripts/deploy-full-stack.sh
    echo "✅ Restored: scripts/deploy-full-stack.sh"
fi

# 2. Restore Documentation
if [ -f "FULL-STACK-DEPLOYMENT.md" ]; then
    mv FULL-STACK-DEPLOYMENT.md FULL-STACK-DEPLOYMENT.md
    echo "✅ Restored: FULL-STACK-DEPLOYMENT.md"
fi

echo ""
echo "Files restored. To revert content changes (references), run:"
echo "git checkout README.md PROJECT-STRUCTURE.md DEPLOYMENT-GUIDE.md QUICK-REFERENCE.md MANUAL_RELEASE_GUIDE.md docs/SECURITY-AND-TESTING-GUIDE.md scripts/nodes-config/automate-node-config.sh"
