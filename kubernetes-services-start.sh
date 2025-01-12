#!/bin/bash

# Wait for kubernetes to be ready
until kubectl get nodes
do
    echo "Waiting for Kubernetes to be ready..."
    sleep 5
done

# Check and create namespaces if needed
kubectl create namespace jhub2 --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace kubernetes-dashboard --dry-run=client -o yaml | kubectl apply -f -

# Apply MetalLB configuration
kubectl apply -f metallb-config.yaml

# Start JupyterHub
helm upgrade --install jhub2 jupyterhub/jupyterhub \
    --namespace jhub2 \
    --values jupyterhub-config.yaml \
    --version=3.3.8

# Start Dashboard
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
    --namespace kubernetes-dashboard \
    --values dashboard-config.yaml

# Recreate dashboard user and permissions
kubectl apply -f dashboard-user.yaml
kubectl apply -f dashboard-clusterrolebinding.yaml

# Wait for services to be ready
kubectl wait --for=condition=ready pod -l app=jupyterhub -n jhub2 --timeout=300s
kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=300s

echo "Services started successfully!"
