#!/bin/bash
# -------------------------------------------------------
# Master post-install script — runs after terraform apply
# Installs: kubectl config, Helm, ArgoCD
# Usage: ./scripts/install-all.sh <resource-group> <cluster-name>
# -------------------------------------------------------
set -euo pipefail

RESOURCE_GROUP=${1:-"voting-app-rg"}
CLUSTER_NAME=${2:-"voting-aks"}

echo "==> [1/3] Configuring kubectl..."
bash "$(dirname "$0")/01-kubectl-config.sh" "$RESOURCE_GROUP" "$CLUSTER_NAME"

echo "==> [2/3] Installing Helm..."
bash "$(dirname "$0")/02-install-helm.sh"

echo "==> [3/3] Installing ArgoCD..."
bash "$(dirname "$0")/03-install-argocd.sh"

echo ""
echo "All tools installed successfully!"
echo "ArgoCD UI: run -> kubectl port-forward svc/argocd-server -n argocd 8080:443"
