#!/bin/bash

################################################################################
# Google Kubernetes Engine (GKE) Fundamentals Lab
# Purpose: Create GKE clusters and deploy containerized applications
# Exam Topics: GKE, Kubernetes, Deployments, Services, Load Balancers
################################################################################

# ==============================================================================
# GKE CLUSTER CONFIGURATION
# ==============================================================================

# gcloud config set compute/region <REGION>
# Sets default region for compute resources
# Exam Tip: Regions contain multiple zones for high availability
# Common regions: us-central1, us-east1, europe-west1, asia-east1
gcloud config set compute/region us-east4

# gcloud config set compute/zone <ZONE>
# Sets default zone for compute resources
# Zone: Isolated location within a region (e.g., us-east4-a, us-east4-b)
# Exam Tip: Zone determines where GKE nodes are created
gcloud config set compute/zone us-east4-b

# ==============================================================================
# CREATE GKE CLUSTER
# ==============================================================================

# gcloud container clusters create <CLUSTER_NAME>
# Creates a Google Kubernetes Engine cluster
# --machine-type=e2-medium: VM type for worker nodes (2 vCPU, 4GB RAM)
# --zone: Where to create the cluster
# Default: 3 nodes, auto-repair enabled, auto-upgrade enabled
# Exam Tip: GKE = Managed Kubernetes, Google handles control plane
# Use Case: Run containerized applications with orchestration
# Pricing: Per node per hour + GKE management fee
gcloud container clusters create --machine-type=e2-medium \
  --zone=us-east4-b lab-cluster

# ==============================================================================
# CONNECT TO CLUSTER
# ==============================================================================

# gcloud container clusters get-credentials <CLUSTER_NAME>
# Configures kubectl to use the GKE cluster
# Effect: Updates ~/.kube/config with cluster credentials
# Exam Tip: Required before running any kubectl commands
# Authentication: Uses your gcloud credentials
gcloud container clusters get-credentials lab-cluster

# ==============================================================================
# KUBERNETES DEPLOYMENT
# ==============================================================================

# kubectl create deployment <NAME> --image=<IMAGE>
# Creates a Kubernetes Deployment (manages pods)
# Deployment: Ensures desired number of pod replicas are running
# --image: Container image from Container Registry
# Default: 1 replica (pod)
# Exam Tip: Deployment → ReplicaSet → Pods (abstraction layers)
# Use Case: Run stateless applications with automatic healing
kubectl create deployment hello-server \
  --image=gcr.io/google-samples/hello-app:1.0

# ==============================================================================
# KUBERNETES SERVICE - EXPOSE DEPLOYMENT
# ==============================================================================

# kubectl expose deployment <NAME>
# Creates a Kubernetes Service (stable network endpoint)
# --type=LoadBalancer: Creates GCP Load Balancer with public IP
# --port: Port that the service listens on
# Exam Tip: Service types:
#   - ClusterIP: Internal only (default)
#   - NodePort: Exposes on each node's IP
#   - LoadBalancer: Creates cloud load balancer (public IP)
#   - ExternalName: DNS CNAME record
# Use Case: Expose application to internet with stable endpoint
kubectl expose deployment hello-server --type=LoadBalancer --port 8080

# kubectl get service
# Lists all services in the cluster
# Shows: Name, Type, Cluster-IP, External-IP, Port(s), Age
# Exam Tip: External-IP takes a few minutes to provision
# Wait for EXTERNAL-IP (not <pending>) before testing
kubectl get service

# ==============================================================================
# DELETE GKE CLUSTER
# ==============================================================================

# gcloud container clusters delete <CLUSTER_NAME>
# Deletes the GKE cluster and all resources
# Effect: Removes nodes, pods, services, load balancers
# Exam Tip: Deleting cluster stops billing for nodes and management
# Use Case: Clean up after testing to avoid charges
gcloud container clusters delete lab-cluster

# Access URLs (examples from lab)
# http://[EXTERNAL-IP]:8080
http://[EXTERNAL-IP]:8080
http://34.118.229.232:8080

# ==============================================================================
# SECOND CLUSTER EXAMPLE - NGINX DEPLOYMENT
# ==============================================================================

# Separator
--

# Create another GKE cluster in different region
# Same process as above but in europe-west1-d zone
gcloud container clusters create io --zone europe-west1-d

# Create nginx deployment (specified version 1.27.0)
# Exam Tip: Always specify image versions for production (not :latest)
# nginx: Popular web server and reverse proxy
kubectl create deployment nginx --image=nginx:1.27.0

# Create deployment again (duplicate line in script)
kubectl create deployment nginx --image=nginx:1.27.0

# Expose nginx deployment with LoadBalancer
# Port 80: Standard HTTP port
kubectl expose deployment nginx --port 80 --type LoadBalancer

# List services to get external IP
kubectl get services

# Test nginx deployment
# curl: HTTP client to test the web server
# Should return nginx default welcome page
curl http://35.187.87.83:80


# ==============================================================================
# KUBERNETES PODS - DECLARATIVE CONFIGURATION
# ==============================================================================

# kubectl create -f <FILE>
# Creates Kubernetes resources from YAML file
# -f (file): Path to YAML configuration
# YAML defines: Pod spec, container image, ports, environment variables
# Exam Tip: Declarative (YAML) vs Imperative (kubectl create)
# Best Practice: Use YAML files for production (version control, repeatability)
kubectl create -f pods/fortune-app.yaml

# kubectl get pods
# Lists all pods in the default namespace
# Shows: Name, Ready, Status, Restarts, Age
# Exam Tip: Pod states: Pending, Running, Succeeded, Failed, Unknown
kubectl get pods

# kubectl port-forward <POD_NAME> <LOCAL_PORT>:<POD_PORT>
# Forwards local port to pod port (for testing)
# Use Case: Access pod directly without creating a Service
# Runs in foreground; Ctrl+C to stop
# Exam Tip: Useful for debugging, not for production access
kubectl port-forward fortune-app 10080:8080

# Test port-forwarded pod
# 127.0.0.1: Localhost (your machine)
curl http://127.0.0.1:10080

# ==============================================================================
# EXAMPLE IPs AND HTTPS ENDPOINTS
# ==============================================================================

# Example external IPs from lab
34.77.88.16

# Test HTTPS endpoints with -k flag
# -k (insecure): Skip SSL certificate verification
# Use Case: Testing self-signed certificates
curl -k https://34.38.223.118:31000

curl -k https://34.140.129.222

################################################################################
# LAB COMPLETE - KEY CONCEPTS REVIEW
################################################################################
#
# 1. GKE Cluster Management:
#    - gcloud container clusters create: Create managed K8s cluster
#    - gcloud container clusters get-credentials: Configure kubectl
#    - gcloud container clusters delete: Remove cluster
#    - Machine types: e2-medium, n1-standard-1, etc.
#
# 2. Kubernetes Workloads:
#    - Deployment: Manages ReplicaSets and Pods
#    - ReplicaSet: Ensures desired number of pod replicas
#    - Pod: Smallest deployable unit (one or more containers)
#    - kubectl create deployment: Imperative way to create deployment
#
# 3. Kubernetes Services:
#    - ClusterIP: Internal cluster access only (default)
#    - NodePort: Exposes on each node's IP:port
#    - LoadBalancer: Provisions cloud load balancer
#    - kubectl expose: Create service for deployment
#
# 4. Kubernetes Commands:
#    - kubectl create: Create resources (imperative or from file)
#    - kubectl get: List resources (pods, services, deployments)
#    - kubectl expose: Create service for deployment
#    - kubectl port-forward: Forward local port to pod
#    - kubectl create -f: Create from YAML file (declarative)
#
# 5. YAML vs Imperative:
#    - Imperative: kubectl create deployment (one-off commands)
#    - Declarative: kubectl apply -f file.yaml (version controlled)
#    - Best Practice: Use YAML files for production
#
# 6. GKE vs Cloud Run:
#    - GKE: Full Kubernetes control, complex deployments, stateful apps
#    - Cloud Run: Simpler, serverless, stateless apps, auto-scaling
#    - Choose GKE for: Complex microservices, batch jobs, ML workloads
#    - Choose Cloud Run for: Web apps, APIs, event-driven functions
#
################################################################################