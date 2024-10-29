# Detailed Kubernetes and JupyterHub Setup Documentation

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation of Required Tools](#installation-of-required-tools)
   - [Docker Installation](#docker-installation)
   - [kubectl Installation](#kubectl-installation)
   - [kubeadm Installation](#kubeadm-installation)
   - [Helm Installation](#helm-installation)
3. [Kubernetes Cluster Setup](#kubernetes-cluster-setup)
4. [Networking Setup](#networking-setup)
5. [Kubernetes Dashboard Installation](#kubernetes-dashboard-installation)
6. [JupyterHub Installation](#jupyterhub-installation)
7. [Accessing Services](#accessing-services)
8. [Troubleshooting](#troubleshooting)

## Prerequisites
- A Linux system (Ubuntu 20.04 or later recommended)
- `sudo` access
- Internet connection

## Installation of Required Tools

### Docker Installation

1. Update the package index:
   ```bash
   sudo apt-get update
   ```

2. Install packages to allow apt to use a repository over HTTPS:
   ```bash
   sudo apt-get install -y \
       apt-transport-https \
       ca-certificates \
       curl \
       gnupg \
       lsb-release
   ```

3. Add Docker's official GPG key:
   ```bash
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   ```

4. Set up the stable repository:
   ```bash
   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```

5. Install Docker Engine:
   ```bash
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io
   ```

6. Verify that Docker Engine is installed correctly:
   ```bash
   sudo docker run hello-world
   ```

### kubectl Installation

1. Download the latest release:
   ```bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   ```

2. Install kubectl:
   ```bash
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   ```

3. Verify the installation:
   ```bash
   kubectl version --client
   ```

### kubeadm Installation

1. Update the apt package index and install packages needed to use the Kubernetes apt repository:
   ```bash
   sudo apt-get update
   sudo apt-get install -y apt-transport-https ca-certificates curl
   ```

2. Download the Google Cloud public signing key:
   ```bash
   sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
   ```

3. Add the Kubernetes apt repository:
   ```bash
   echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
   ```

4. Update apt package index, install kubeadm, kubelet and kubectl, and pin their version:
   ```bash
   sudo apt-get update
   sudo apt-get install -y kubelet kubeadm kubectl
   sudo apt-mark hold kubelet kubeadm kubectl
   ```

### Helm Installation

1. Download the Helm installation script:
   ```bash
   curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
   ```

2. Make the script executable:
   ```bash
   chmod 700 get_helm.sh
   ```

3. Run the script:
   ```bash
   ./get_helm.sh
   ```

4. Verify the installation:
   ```bash
   helm version
   ```

## Kubernetes Cluster Setup

1. Disable swap:
   ```bash
   sudo swapoff -a
   ```

2. Initialize the Kubernetes cluster:
   ```bash
   sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --cri-socket=unix:///var/run/cri-dockerd.sock
   ```

3. Set up kubectl for the current user:
   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

4. Untaint the control-plane node to allow pod scheduling:
   ```bash
   kubectl taint nodes $(hostname) node-role.kubernetes.io/control-plane-
   ```

## Networking Setup

1. Apply Flannel network plugin:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
   ```

2. Verify that all pods are running:
   ```bash
   kubectl get pods --all-namespaces
   ```

## Kubernetes Dashboard Installation

1. Add the Kubernetes Dashboard Helm repository:
   ```bash
   helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
   ```

2. Install the Kubernetes Dashboard:
   ```bash
   helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
     --create-namespace --namespace kubernetes-dashboard
   ```

3. Create a dashboard admin account:
   ```bash
   kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard
   kubectl create clusterrolebinding dashboard-admin \
     --clusterrole=cluster-admin \
     --serviceaccount=kubernetes-dashboard:dashboard-admin
   ```

4. Get the token for dashboard access:
   ```bash
   kubectl -n kubernetes-dashboard create token dashboard-admin
   ```

## JupyterHub Installation

1. Add the JupyterHub Helm repository:
   ```bash
   helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
   helm repo update
   ```

2. Create a `jupyterhub-config.yaml` file with the following content:
   ```yaml
   hub:
     config:
       Spawner:
         cpu_limit: 4
         mem_limit: '16G'
       JupyterHub:
         auth:
           type: dummy
           dummy:
             password: 'set-a-secure-password'
     
     extraConfig:
       proxy:
         secretToken: "generate-a-secret-token-here"

   singleuser:
     extraResource:
       guarantees:
         cpu: "1"
         memory: 4Gi
       limits:
         cpu: "4"
         memory: 16Gi
         nvidia.com/gpu: "1"
     profileList:
       - display_name: "Small Instance"
         description: "Minimum resources for light workloads"
         kubespawner_override:
           cpu_guarantee: 1
           cpu_limit: 2
           mem_guarantee: "4G"
           mem_limit: "8G"
       - display_name: "GPU Instance"
         description: "Instance with GPU"
         kubespawner_override:
           cpu_guarantee: 2
           cpu_limit: 4
           mem_guarantee: "16G"
           mem_limit: "32G"
           extra_resource_limits:
             nvidia.com/gpu: "1"

   proxy:
     secretToken: "generate-a-secret-token-here"

   scheduling:
     userScheduler:
       enabled: true
     podPriority:
       enabled: true
     userPlaceholder:
       enabled: true
       replicas: 2

   cull:
     enabled: true
     timeout: 3600
     every: 300

   singleuser:
     storage:
       type: dynamic
       dynamic:
         storageClass: local-storage
       capacity: 10Gi
   ```

3. Install JupyterHub using Helm:
   ```bash
   helm install jhub jupyterhub/jupyterhub \
     --namespace jhub \
     --create-namespace \
     --version=3.3.8 \
     --values jupyterhub-config.yaml
   ```

4. Verify the installation:
   ```bash
   kubectl get pods -n jhub
   ```

## Accessing Services

### Kubernetes Dashboard
1. Start the proxy:
   ```bash
   kubectl -n kubernetes-dashboard port-forward --address 0.0.0.0 svc/kubernetes-dashboard-kong-proxy 8443:443
   ```
2. Access the dashboard at `https://<your-ip>:8443`
3. Use the token generated earlier for authentication

### JupyterHub
1. Start the proxy:
   ```bash
   kubectl port-forward --address 0.0.0.0 -n jhub svc/proxy-public 8888:80
   ```
2. Access JupyterHub at `http://<your-ip>:8888`

## Troubleshooting

- If pods are stuck in Pending state, check node status and ensure resources are available:
  ```bash
  kubectl describe node <node-name>
  ```

- For networking issues, verify that the Flannel network plugin is properly installed and running:
  ```bash
  kubectl get pods -n kube-system | grep flannel
  ```

- Check logs of specific pods using:
  ```bash
  kubectl logs -n <namespace> <pod-name>
  ```

- For persistent volume issues, ensure that the storage class is properly configured and available:
  ```bash
  kubectl get sc
  kubectl describe sc local-storage
  ```

- If JupyterHub is not accessible, check the status of the jhub release:
  ```bash
  helm status jhub -n jhub
  ```

- To check the events in a namespace for troubleshooting:
  ```bash
  kubectl get events -n <namespace>
  ```

Remember to replace placeholders like `<your-ip>`, `<node-name>`, and `generate-a-secret-token-here` with your actual values.

For security reasons, make sure to change default passwords and tokens, and consider implementing more robust authentication methods in a production environment.
