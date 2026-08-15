#!/bin/bash
# -------------------------------------------------------
# 03-install-argocd.sh
# Installs ArgoCD into the argocd namespace via Helm
# -------------------------------------------------------
set -euo pipefail

NAMESPACE="argocd"
RELEASE="argocd"

echo "Creating namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "Installing ArgoCD via Helm..."
helm upgrade --install "$RELEASE" argo/argo-cd \
  --namespace "$NAMESPACE" \
  --set server.service.type=ClusterIP \
  --set configs.params."server\.insecure"=false \
  --wait

echo "Waiting for ArgoCD pods to be ready..."
kubectl rollout status deployment/argocd-server -n "$NAMESPACE" --timeout=120s

# Fetch the initial admin password
echo ""
echo "ArgoCD installed successfully!"
echo "Initial admin password:"
kubectl -n "$NAMESPACE" get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo ""
echo "Access ArgoCD UI:"
echo "  kubectl port-forward svc/argocd-server -n $NAMESPACE 8080:443"
echo "  Then open: https://localhost:8080  (user: admin)"
