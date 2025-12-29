#!/bin/bash

################################################################################
# Docker and Container Management on GCP Compute Engine
# Purpose: Manage Docker containers on VMs, configure Docker registry auth
# Exam Topics: Compute Engine, Docker, Artifact Registry, Container Management
################################################################################

# ==============================================================================
# CONNECT TO VM INSTANCE
# ==============================================================================

# gcloud compute ssh <INSTANCE_NAME>
# SSH into a Compute Engine VM instance
# --zone: Zone where the VM is located
# Effect: Opens interactive SSH session to the VM
# Exam Tip: Requires firewall rule allowing SSH (port 22) - default VPC allows it
# Use Case: Access VMs for configuration, debugging, or management
# Authentication: Uses your gcloud credentials or SSH keys
gcloud compute ssh lab-vm --zone=us-west1-b

# ==============================================================================
# DOCKER SOCKET PERMISSIONS
# ==============================================================================

# sudo chmod 666 /var/run/docker.sock
# Changes permissions on Docker socket file
# 666: Read/write for owner, group, and others (rwxrwxrwx)
# /var/run/docker.sock: Unix socket for Docker daemon communication
# Effect: Allows non-root users to run Docker commands
# Security Warning: Less secure than adding user to docker group
# Exam Tip: Alternative (better): sudo usermod -aG docker $USER
# Use Case: Quick permission fix for testing (not recommended for production)
sudo chmod 666 /var/run/docker.sock

# ==============================================================================
# STOP DOCKER CONTAINERS
# ==============================================================================

# docker stop [CONTAINER ID]
# Stops a specific running container
# Exam Tip: Replace [CONTAINER ID] with actual container ID
docker stop [CONTAINER ID]

# ==============================================================================
# CONFIGURE ARTIFACT REGISTRY AUTHENTICATION
# ==============================================================================

# gcloud auth configure-docker <REGISTRY_URL>
# Configures Docker to authenticate with Artifact Registry
# ${REGION}-docker.pkg.dev: Regional Artifact Registry endpoint
# Effect: Updates ~/.docker/config.json with credential helper
# Exam Tip: Must run before pushing/pulling from Artifact Registry
# Format examples:
#   - us-docker.pkg.dev (multi-region)
#   - us-central1-docker.pkg.dev (regional)
#   - gcr.io (legacy Container Registry)
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# ==============================================================================
# STOP ALL RUNNING CONTAINERS
# ==============================================================================

# docker stop $(docker ps -q)
# Stops all currently running containers
# docker ps -q: Lists only container IDs (quiet mode)
# $(...): Command substitution - passes IDs to docker stop
# Exam Tip: Graceful shutdown (sends SIGTERM, waits, then SIGKILL)
# Use Case: Quick cleanup of all running containers
docker stop $(docker ps -q)

# ==============================================================================
# REMOVE ALL CONTAINERS
# ==============================================================================

# docker rm $(docker ps -aq)
# Removes all containers (stopped and exited)
# docker ps -aq: All containers (-a), only IDs (-q)
# Exam Tip: Can't remove running containers without -f (force)
# Effect: Deletes container and its writable layer (not the image)
docker rm $(docker ps -aq)

# ==============================================================================
# REMOVE SPECIFIC IMAGE
# ==============================================================================

# docker rmi <IMAGE_URL>
# Removes Docker image from local machine
# Full image URL format: REGISTRY/PROJECT/REPO/IMAGE:TAG
# Exam Tip: Can't remove if containers are using the image
# Use Case: Free up disk space, remove old versions
docker rmi ${REGION}-docker.pkg.dev/$PROJECT_ID/my-repo/my-app:0.2

# ==============================================================================
# REMOVE ALL IMAGES
# ==============================================================================

# docker rmi -f $(docker images -aq)
# Force removes ALL images on local machine
# -f (force): Remove even if containers reference it
# docker images -aq: All images (-a), only IDs (-q)
# Exam Tip: Very destructive - use carefully
# Use Case: Complete cleanup before starting fresh
docker rmi -f $(docker images -aq)

################################################################################
# LAB COMPLETE - KEY CONCEPTS REVIEW
################################################################################
#
# 1. Compute Engine and Docker:
#    - gcloud compute ssh: Access VM instances
#    - Docker daemon runs on VM (not managed by GCP)
#    - Must install Docker on VM (or use Container-Optimized OS)
#    - /var/run/docker.sock: Unix socket for Docker API
#
# 2. Docker Socket Permissions:
#    - Default: Only root can access Docker socket
#    - chmod 666: Allows all users (insecure)
#    - Better: Add user to docker group
#    - Best: Use service accounts and IAM for Cloud Run
#
# 3. Artifact Registry Authentication:
#    - gcloud auth configure-docker: Sets up Docker credential helper
#    - Automatic authentication using gcloud credentials
#    - Regional endpoints: <REGION>-docker.pkg.dev
#    - Legacy: gcr.io (Container Registry)
#
# 4. Docker Container Management:
#    - docker ps: List running containers
#    - docker ps -a: List all containers (including stopped)
#    - docker stop: Gracefully stop container
#    - docker rm: Remove stopped container
#    - docker stop $(docker ps -q): Stop all running
#
# 5. Docker Image Management:
#    - docker images: List local images
#    - docker rmi: Remove image
#    - docker rmi -f: Force remove
#    - Can't remove image if containers use it (without -f)
#
# 6. Best Practices:
#    - Use Container-Optimized OS for GCE when running containers
#    - Consider Cloud Run instead of managing Docker on VMs
#    - Use specific image tags (not :latest)
#    - Clean up unused containers/images regularly
#    - Use IAM for registry authentication (not Docker login)
#
# 7. Common Patterns:
#    - Stop all: docker stop $(docker ps -q)
#    - Remove all containers: docker rm $(docker ps -aq)
#    - Remove all images: docker rmi $(docker images -q)
#    - Force remove all: docker rmi -f $(docker images -aq)
#
################################################################################