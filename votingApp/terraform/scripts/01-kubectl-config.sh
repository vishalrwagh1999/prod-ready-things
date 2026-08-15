#!/bin/bash
# -------------------------------------------------------
# 01-kubectl-config.sh
# Gets AKS credentials and sets current kubectl context
# -------------------------------------------------------
set -euo pipefail

RESOURCE_GROUP=${1:-"voting-app-rg"}
CLUSTER_NAME=${2:-"voting-aks"}

echo "Fetching AKS credentials for cluster: $CLUSTER_NAME"
az aks get-credentials \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CLUSTER_NAME" \
  --overwrite-existing

echo "Verifying cluster connection..."
kubectl get nodes
