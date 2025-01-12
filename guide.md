# JupyterHub and Kubernetes Dashboard Operations Guide

## Overview

This guide provides comprehensive instructions for managing and operating a JupyterHub deployment on Kubernetes, including system checks, user management, troubleshooting, and maintenance procedures.

## Prerequisites

- Kubernetes cluster
- `kubectl` command-line tool
- Helm package manager
- JupyterHub installed
- Kubernetes Dashboard installed

## 1. Initial System Verification

### 1.1 Cluster Node Status

Verify all nodes are operational:

```bash
kubectl get nodes
```

**Expected Output:**
```
NAME           STATUS   ROLES           AGE    VERSION
exxact-10887   Ready    control-plane   10d    v1.28.2
worker1        Ready    <none>          10d    v1.28.2
worker2        Ready    <none>          10d    v1.28.2
```

### 1.2 System Pods

Check system-critical pods:

```bash
kubectl get pods --all-namespaces
```

**Expected Output:**
```
NAMESPACE              NAME                                        READY   STATUS    RESTARTS   AGE
kube-system           coredns-*                                   1/1     Running   0          10d
metallb-system        controller-*                                1/1     Running   0          10d
metallb-system        speaker-*                                   1/1     Running   0          10d
```

### 1.3 Storage Configuration

Verify storage classes:

```bash
kubectl get storageclass
```

**Expected Output:**
```
NAME         PROVISIONER             AGE
nfs-client   cluster.local/nfs       10d
```

## 2. Cluster Health Verification

### 2.1 MetalLB Configuration

Check MetalLB configuration:

```bash
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system
```

**Expected Output:**
```
NAME         AUTO ASSIGN   ADDRESSES            AVOID BUGGY IPS
first-pool   true          10.105.10.200-220    false
```

### 2.2 Ingress Controller

Check ingress controller:

```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

**Expected Output:**
```
NAME                                        READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-*                  1/1     Running   0          10d

NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)
ingress-nginx-controller            LoadBalancer   10.99.179.191   10.105.10.200   80:30300/TCP,443:30109/TCP
```

## 3. JupyterHub Operations

### 3.1 Check JupyterHub Installation

```bash
# Check namespace
kubectl get namespace jhub2

# Check all resources in jhub2 namespace
kubectl get all -n jhub2
```

**Expected Output:**
- Running hub pod
- Running proxy pod
- Running user pods (if any)

### 3.2 Verify JupyterHub Configuration

```bash
# Get current config
helm get values jhub2 -n jhub2
```

### 3.3 Admin Access

1. Get ingress address:
```bash
kubectl get ingress -n jhub2
```

2. Access JupyterHub:
- Visit `http://jupyter.sail` or `http://jupyterhub2.local`
- Login as admin user (aagar8)
- Verify "Admin" panel is visible

### 3.4 Profile Access Verification

```bash
# Check profile configuration
kubectl get configmap -n jhub2 jupyterhub-config -o yaml
```

Test profile access:
- Login as different users:
  - aagar8 (admin, all profiles)
  - user1 (limited profiles)
  - test (single profile)

```bash
# Check running user pods
kubectl get pods -n jhub2 -l component=singleuser-server
```

## 4. Kubernetes Dashboard Operations

### 4.1 Dashboard Access

```bash
# Start port forwarding
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-web 8443:8000
```

Access: https://localhost:8443

### 4.2 Get Access Token

```bash
# Create token
kubectl create token dashboard-user -n kubernetes-dashboard
```

### 4.3 Verify Dashboard Functionality

1. Check Cluster Overview
2. Check Workloads
3. Access Pod Logs
4. Check Resource Usage

## 5. User Management and Testing

### 5.1 Test User Creation

```bash
# Create test users
for user in testuser{1..3}; do
    # Create user in JupyterHub
    # Access via web interface
done
```

### 5.2 Profile Access Testing

For each test user:
1. Login to JupyterHub
2. Verify available profiles
3. Launch each available profile
4. Verify resource allocation

```bash
# Check pod resources
kubectl describe pod -n jhub2 jupyter-testuser1

# Check GPU allocation
kubectl exec -it -n jhub2 jupyter-testuser1 -- nvidia-smi
```

### 5.3 Resource Verification

```bash
# Check node resources
kubectl describe nodes | grep -A 5 "Allocated resources"

# Check GPU allocation
kubectl get pods -n jhub2 -o custom-columns=NAME:.metadata.name,GPU:.spec.containers[*].resources.limits."nvidia\.com/gpu"
```

## 6. Troubleshooting

### 6.1 JupyterHub Issues

```bash
# Check hub logs
kubectl logs -n jhub2 $(kubectl get pods -n jhub2 -l component=hub -o name)

# Check proxy logs
kubectl logs -n jhub2 $(kubectl get pods -n jhub2 -l component=proxy -o name)

# Check user pod logs
kubectl logs -n jhub2 jupyter-username
```

Common troubleshooting steps:
1. Pod scheduling failures
```bash
kubectl describe pod -n jhub2 <pod-name>
```
Look for:
- Resource constraints
- Node selector issues
- Volume mount issues

2. Profile access issues
```bash
kubectl get configmap -n jhub2 jupyterhub-config -o yaml
```

3. Storage issues
```bash
# Check PVCs
kubectl get pvc -n jhub2

# Check PVs
kubectl get pv
```

### 6.2 Dashboard Issues

```bash
# Check dashboard pods
kubectl get pods -n kubernetes-dashboard

# Check logs
kubectl logs -n kubernetes-dashboard $(kubectl get pods -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard -o name)
```

## 7. Maintenance Operations

### 7.1 Backup Configurations

```bash
# Backup all configurations
kubectl get all -n jhub2 -o yaml > jhub_backup.yaml
kubectl get configmap -n jhub2 -o yaml > jhub_configmaps.yaml
kubectl get secret -n jhub2 -o yaml > jhub_secrets.yaml
```

### 7.2 Update Operations

```bash
# Update JupyterHub
helm upgrade jhub2 jupyterhub/jupyterhub \
  --namespace jhub2 \
  --values config.yaml \
  --version=3.3.8

# Verify update
kubectl rollout status deployment/hub -n jhub2
```

### 7.3 Regular Maintenance

```bash
# Check pod resource usage
kubectl top pods -n jhub2

# Check node resource usage
kubectl top nodes

# Check storage usage
kubectl get pvc -n jhub2
```

### 7.4 Cleanup Operations

```bash
# Remove inactive user pods
kubectl get pods -n jhub2 | grep "jupyter-" | grep "Completed\|Error" | awk '{print $1}' | xargs kubectl delete pod -n jhub2

# Clean old PVCs
kubectl get pvc -n jhub2 | grep Lost | awk '{print $1}' | xargs kubectl delete pvc -n jhub2
```

## Success Criteria Checklist

### JupyterHub
- [ ] Admin interface accessible
- [ ] All profiles available to admin
- [ ] User profile restrictions working
- [ ] GPU allocation functioning correctly
- [ ] Storage persistence working
- [ ] User pods starting correctly

### Kubernetes Dashboard
- [ ] Dashboard accessible via port-forward
- [ ] Token authentication working
- [ ] Full cluster visibility
- [ ] Resource monitoring working

### System Health
- [ ] All nodes Ready
- [ ] Storage provisioner working
- [ ] MetalLB configured correctly
- [ ] Ingress controller functioning

## Disclaimer

Ensure you have proper permissions and understand the implications of each command before executing.

---

**Version:** 1.0.0
**Last Updated:** 12-18-2024
