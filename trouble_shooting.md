
# Troubleshooting Guide for Kubernetes and JupyterHub After Reboot

This guide provides step-by-step troubleshooting instructions to nsure your Kubernetes cluster and JupyterHub service are running correctly after a system reboot.

## Initial Checks

1. Verify GPU Availability
    Run the following command to check if the GPU is accessible:
      ```bash
      nvidia-smi
      ```
    Ensure the GPUs are detected correctly. If not, confirm that the NVIDIA drivers and CUDA are installed and properly configured.

2. Network Connectivity
	a. Check Ping to Master Node
      Verify connectivity to the master node:
      ```bash
      ping 10.105.10.80
      ```
	b. Check Kubernetes API Port
  		Ensure the Kubernetes API is accessible:
  		```bash
		nc -zv 10.105.10.80 6443
  		```
	c. Check Access to Services in Browser
	    Use port-forwarding or the service's external IP to verify that the services are reachable in a browser. Replace <ip> and <port> with actual values.
    	```bash
    	kubectl port-forward --address 0.0.0.0 -n jhub svc/proxy-public 8888:80
    	```

## Restart and Validation Commands

1. Restart kubelet Service
	Restart the Kubernetes node manager:
	```bash
	sudo systemctl restart kubelet
	```
	Verify the status of the kubelet service:
	```bash
	sudo systemctl status kubelet
	```
2. Verify Kubernetes Context
	Check the current Kubernetes contexts:
	```bash
	kubectl config get-contexts
	```
3. Check Cluster State
	a. Verify Pods in All Namespaces
		```bash
		kubectl get pods --all-namespaces
		```
	b. Check API Server Pods
		```bash
		kubectl -n kube-system get pods | grep apiserver
		```
	c. Check API Port Binding
		Ensure the Kubernetes API server is bound to the correct port:
		```bash
		sudo netstat -tuln | grep 6443
		```
## Reinitialize Kubernetes (If Necessary)

1. If the cluster fails to start, reinitialize it:
    Disable swap:
    ```bash
	sudo swapoff -a
	```
2. Initialize Kubernetes:
	```bash
	sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --cri-socket=unix:///var/run/cri-dockerd.sock
	```
3. Reapply network plugin (Flannel):
	```bash
		kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
		```
4. Verify all pods are running:
	```bash
    kubectl get pods --all-namespaces
	```

## Helm Commands for JupyterHub
1. Upgrade JupyterHub Release
	If JupyterHub fails to start, upgrade the release:
	```bash
	helm upgrade jhub2 jupyterhub/jupyterhub -f jupyterhub-config_oct28.yaml -n jhub2
	```
2. Verify JupyterHub Pods
	Check the status of JupyterHub pods:
	```bash
	kubectl --namespace=jhub2 get pod
	```
3. Delete Faulty Pods
	If any pods are in an error state, delete and recreate them:
	```bash
	kubectl delete pod <pod-name> -n jhub2
	```
4. Check Services
	Verify the services in the namespace:
	```bash
	kubectl get svc -n jhub2
	```
	Describe a specific service if needed:
	```bash
	kubectl describe svc -n jhub2
	```
## Access JupyterHub

To access JupyterHub, use port-forwarding:
```bash
kubectl port-forward --address 0.0.0.0 -n jhub2 svc/proxy-public 8888:80
```
Open the following URL in your browser:
```bash
http://<your-ip>:8888
```
## Additional Debugging

### Check Events in Namespace
If issues persist, view recent events in the namespace:
```bash
kubectl get events -n jhub2
```
### Inspect Pod Logs
Retrieve logs for a specific pod:
```bash
kubectl logs -n jhub2 <pod-name>
```
### Storage Troubleshooting
Ensure the storage class is properly configured:
```bash
kubectl get sc
kubectl describe sc local-storage
```
## Final Notes
Always replace placeholders (e.g., <your-ip>, <pod-name>) with actual values.
Regularly monitor system resources (nvidia-smi, kubectl top nodes) to prevent resource exhaustion.
