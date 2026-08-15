#!/bin/bash
# -------------------------------------------------------
# 02-install-helm.sh
# Installs Helm v3 if not already installed
# -------------------------------------------------------
set -euo pipefail

if command -v helm &>/dev/null; then
  echo "Helm already installed: $(helm version --short)"
  exit 0
fi

echo "Installing Helm v3..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "Helm installed: $(helm version --short)"

# Add commonly used Helm repos
echo "Adding Helm repos..."
helm repo add stable        https://charts.helm.sh/stable
helm repo add bitnami       https://charts.bitnami.com/bitnami
helm repo add argo          https://argoproj.github.io/argo-helm
helm repo update

echo "Helm repos configured."
