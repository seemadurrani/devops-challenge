#!/bin/bash

set -e

echo "Creating 'argocd' namespace..."
kubectl create namespace argocd || echo "Namespace 'argocd' already exists."

echo "Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD pods to be ready..."
kubectl rollout status deployment/argocd-server -n argocd
kubectl rollout status deployment/argocd-repo-server -n argocd
kubectl rollout status deployment/argocd-application-controller -n argocd
kubectl rollout status deployment/argocd-dex-server -n argocd

echo "Port-forwarding Argo CD UI to https://localhost:8080 ..."
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
sleep 3

echo "Fetching Argo CD admin password..."
ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 --decode)

echo -e "\n✅ Argo CD installed successfully!"
echo "🌐 UI: https://localhost:8080"
echo "👤 Username: admin"
echo "🔐 Password: $ARGOCD_PWD"
