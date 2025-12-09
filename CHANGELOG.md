# Changelog

All notable changes to the DhakaCart project will be documented in this file.

## [2025-12-09] - Deployment Automation & Cleanup

### Added
-   **Hostname Automation**: Added `--yes` flag to `change-hostname-via-bastion.sh` for non-interactive execution.
-   **Integration**: Integrated hostname change step into `deploy-4-hour-window.sh`.
-   **Manual Verification Output**: Added detailed list of manual verification steps at the end of the deployment script.

### Changed
-   **Dynamic IPs**: Updated `sync-k8s-to-master1.sh` to load IPs dynamically from `load-infrastructure-config.sh` instead of hardcoded values.
-   **Directory Structure**: Moved `terraform/simple-k8s/nodes-config-steps/` to `scripts/nodes-config/` for better organization.
-   **Script Updates**: Updated `deploy-4-hour-window.sh` and `extract-terraform-outputs.sh` to use the new `scripts/nodes-config/` path.
-   **Documentation**: Updated `PROJECT-STRUCTURE.md`, `DEPLOYMENT-GUIDE.md`, `4-HOUR-DEPLOYMENT.md`, and `QUICK-REFERENCE.md` to reflect new paths and automation steps.
-   **README Merge**: Merged `terraform/README.md` and `simple-k8s/docs/README.md` into a single, unified `terraform/README.md`.
-   **Testing**: Updated `simulation/load-tests/run-load-test.sh` to auto-detect ALB URL. Updated `testing/README.md`, `SECURITY-AND-TESTING-GUIDE.md`, `4-HOUR-DEPLOYMENT.md`, `QUICK-REFERENCE.md`, and `DEPLOYMENT-GUIDE.md` with streamlined instructions.
-   **Main README**: Completely overhauled `/home/arif/DhakaCart-03-test/README.md` to be more structural, architectural, and prioritized the new automated deployment workflows. Added Mermaid diagrams and cleaned up outdated links.

### Removed
-   Archived obsolete documentation files (`AUTOMATION_PLAN_2025-11-29.md`, `DEPLOYMENT_SUCCESS.md`, etc.) to `archive-2025-dec-cleanup/`.

### Fixed
-   **K8s Upload Failure**: Resolved issue where `sync-k8s-to-master1.sh` failed to upload files due to incorrect/static IP addresses.
-   **Hostname "0-All"**: Automating the script bypasses the manual confirmation issue.
