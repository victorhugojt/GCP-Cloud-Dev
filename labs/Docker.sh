#!/bin/bash

################################################################################
# Docker Fundamentals and GCP Container Registry Lab
# Purpose: Learn Docker basics and push images to Artifact Registry
# Exam Topics: Docker, Containers, Artifact Registry, Image Management
################################################################################

# ==============================================================================
# CREATE DOCKERFILE
# ==============================================================================

# Create Dockerfile using heredoc
# Dockerfile: Text file with instructions to build a container image
# Each instruction creates a layer in the image
cat > Dockerfile <<EOF
# FROM: Base image to build upon
# node:lts - Official Node.js image, Long Term Support version
# Exam Tip: Always use specific versions in production (e.g., node:18-alpine)
FROM node:lts

# WORKDIR: Sets working directory inside container
# All subsequent commands execute from this directory
# Creates directory if it doesn't exist
WORKDIR /app

# ADD: Copy files from host to container
# . /app: Current directory → /app in container
# Similar to COPY but ADD can also extract archives and download URLs
# Exam Tip: Prefer COPY over ADD unless you need archive extraction
ADD . /app

# EXPOSE: Documents which port the container listens on
# Does NOT actually publish the port (informational only)
# Use -p flag when running container to map ports
EXPOSE 80

# CMD: Default command to run when container starts
# ["node", "app.js"]: Exec form (preferred, doesn't invoke shell)
# Exam Tip: One CMD per Dockerfile; CMD vs ENTRYPOINT differences
CMD ["node", "app.js"]
EOF

# ==============================================================================
# CREATE APPLICATION FILE
# ==============================================================================

# Create simple Node.js HTTP server
cat > app.js << EOF;
const http = require("http");

const hostname = "0.0.0.0";
const port = 80;

const server = http.createServer((req, res) => {
	res.statusCode = 200;
	res.setHeader("Content-Type", "text/plain");
	res.end("Hello World\n");
});

server.listen(port, hostname, () => {
	console.log("Server running at http://%s:%s/", hostname, port);
});

process.on("SIGINT", function () {
	console.log("Caught interrupt signal and will exit");
	process.exit();
});
EOF

# ==============================================================================
# DOCKER IMAGE MANAGEMENT
# ==============================================================================

# docker images
# Lists all Docker images on local machine
# Shows: Repository, Tag, Image ID, Created, Size
# Exam Tip: Images are templates; containers are running instances
docker images

# ==============================================================================
# DOCKER RUN - START CONTAINERS
# ==============================================================================

# docker run -p <HOST_PORT>:<CONTAINER_PORT> --name <NAME> <IMAGE>
# Runs a container from an image
# -p 4000:80: Port mapping (host:container) - maps localhost:4000 → container:80
# --name my-app: Assigns friendly name to container (use instead of random ID)
# node-app:0.1: Image name and tag
# Exam Tip: Without -d (detach), container runs in foreground
# Container runs until main process exits or you stop it
docker run -p 4000:80 --name my-app node-app:0.1

# curl http://localhost:4000
# Test the running container from host machine
# Exam Tip: In Cloud Shell, use web preview for testing
curl http://localhost:4000

# docker stop <CONTAINER> && docker rm <CONTAINER>
# stop: Gracefully stops running container (sends SIGTERM, then SIGKILL)
# rm: Removes stopped container and its writable layer
# Exam Tip: Can't remove running containers without -f (force)
# Use Case: Clean up after testing
docker stop my-app && docker rm my-app

# Run container again (same as first run command)
docker run -p 4000:80 --name my-app node-app:0.1

# ==============================================================================
# DOCKER INSPECT AND DEBUG
# ==============================================================================

# docker ps
# Lists currently running containers
# Shows: Container ID, Image, Command, Created, Status, Ports, Names
# Exam Tip: docker ps -a shows all containers (including stopped)
docker ps

# docker logs <CONTAINER>
# Shows stdout/stderr output from container
# Use Case: Debug application issues, view application logs
# Exam Tip: Containers should log to stdout/stderr (not files)
docker logs b6c49a02d3c3

# docker logs -f <CONTAINER>
# -f (follow): Stream logs in real-time (like tail -f)
# Ctrl+C to exit following mode
docker logs -f 29d7d3d3ce62

# docker exec -it <CONTAINER> <COMMAND>
# Executes command inside running container
# -i (interactive): Keep stdin open
# -t (tty): Allocate pseudo-terminal
# bash: Start interactive shell inside container
# Exam Tip: Container must be running to use exec
# Use Case: Debug issues, inspect container state
docker exec -it 29d7d3d3ce62 bash

docker exec -it my-app bash

# Execute individual commands without entering shell
# ls -l: List files with details
docker exec -it my-app ls -l

# pwd: Print working directory
docker exec -it my-app pwd

# cat: View file contents
docker exec -it my-app cat /app/app.js

docker exec -it my-app cat /app/package.json

# exit
# Exits the interactive shell (if you're inside container)
# Does NOT stop the container (unlike stopping main process)
exit

# ==============================================================================
# DOCKER INSPECT - DETAILED CONTAINER INFORMATION
# ==============================================================================

# docker inspect <CONTAINER>
# Returns detailed JSON information about container
# Includes: Config, Network settings, Mounts, State, etc.
# Exam Tip: Use --format to extract specific fields
# Use Case: Debug networking, check environment variables, verify mounts
docker inspect 29d7d3d3ce62

docker inspect my-app

docker inspect b6c49a02d3c3

docker inspect 29d7d3d3ce62

docker inspect my-app

docker inspect b6c49a02d3c3

# docker inspect --format='<GO_TEMPLATE>' <CONTAINER>
# --format: Uses Go template syntax to extract specific fields
# {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}: Get container IP
# Exam Tip: Useful format examples:
#   - '{{.State.Status}}': Container status
#   - '{{.Config.Env}}': Environment variables
#   - '{{.Mounts}}': Volume mounts
# Use Case: Extract container IP for networking configuration
docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 29d7d3d3ce62

# ==============================================================================
# ARTIFACT REGISTRY SETUP
# ==============================================================================

# gcloud auth configure-docker <REGISTRY_URL>
# Configures Docker to authenticate with GCP Artifact Registry
# Effect: Adds credential helper to ~/.docker/config.json
# Exam Tip: Must run before pushing/pulling from Artifact Registry
# Format: <REGION>-docker.pkg.dev for Artifact Registry
#         gcr.io for Container Registry (legacy)
gcloud auth configure-docker us-west1-docker.pkg.dev

# gcloud artifacts repositories create <REPO_NAME>
# Creates an Artifact Registry repository
# --repository-format=docker: Store Docker/OCI images
# --location: Regional location (affects latency and costs)
# --description: Human-readable description
# Exam Tip: Repository is NOT the same as image; one repo holds many images
# Naming: Use descriptive names for repository purpose
gcloud artifacts repositories create my-repository \
  --repository-format=docker \
  --location=us-west1 \
  --description="Docker repository"

# ==============================================================================
# DOCKER CLEANUP COMMANDS
# ==============================================================================

# docker stop $(docker ps -q)
# Stops all running containers
# docker ps -q: Lists only container IDs (quiet mode)
# $(): Command substitution - passes IDs to docker stop
# Exam Tip: Add -t 0 for immediate stop (no grace period)
docker stop $(docker ps -q)

# docker rm $(docker ps -aq)
# Removes all containers (stopped and running with -f)
# docker ps -aq: All containers, only IDs (-a all, -q quiet)
# Exam Tip: Can't remove running containers without -f flag
docker rm $(docker ps -aq)

# docker rmi <IMAGE>
# Removes Docker image from local machine
# rmi = remove image
# Format: REGISTRY/PROJECT/REPO/IMAGE:TAG
# Exam Tip: Can't remove image if containers are using it
docker rmi us-west1-docker.pkg.dev/qwiklabs-gcp-00-1d92cfdc5a39/my-repository/node-app:0.2

# Remove base image
docker rmi node:lts

# docker rmi -f $(docker images -aq)
# Force removes ALL images on local machine
# -f (force): Remove even if containers reference the image
# docker images -aq: All images, only IDs
# Exam Tip: Use cautiously - deletes everything (good for cleanup)
docker rmi -f $(docker images -aq) # remove remaining images

# docker images
# Verify all images removed (should be empty list)
docker images

################################################################################
# LAB COMPLETE - KEY CONCEPTS REVIEW
################################################################################
#
# 1. Docker Image Basics:
#    - FROM: Base image layer
#    - WORKDIR: Sets working directory
#    - COPY/ADD: Copy files into image
#    - EXPOSE: Document ports (informational)
#    - CMD: Default command when container starts
#
# 2. Docker Container Lifecycle:
#    - docker build: Create image from Dockerfile
#    - docker run: Create and start container
#    - docker stop: Stop running container
#    - docker rm: Remove stopped container
#    - docker rmi: Remove image
#
# 3. Docker Debugging:
#    - docker ps: List running containers
#    - docker logs: View container logs (stdout/stderr)
#    - docker exec -it: Execute commands in running container
#    - docker inspect: Detailed container/image information
#
# 4. Port Mapping:
#    - -p HOST:CONTAINER: Maps ports from container to host
#    - Example: -p 8080:80 (localhost:8080 → container:80)
#    - Allows accessing containerized services from host
#
# 5. GCP Artifact Registry:
#    - Modern replacement for Container Registry (gcr.io)
#    - Supports multiple formats (Docker, Maven, npm, etc.)
#    - Regional repositories (lower latency, compliance)
#    - gcloud auth configure-docker: Authenticate Docker client
#
# 6. Best Practices:
#    - Use specific image versions (not :latest)
#    - Minimize layers (combine RUN commands)
#    - Use .dockerignore to exclude files
#    - Name containers (--name) for easier management
#    - Log to stdout/stderr (not files)
#    - Clean up unused images/containers regularly
#
################################################################################