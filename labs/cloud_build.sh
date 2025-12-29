#!/bin/bash

################################################################################
# Cloud Build with Cloud Run Deployment Lab
# Purpose: Build container images with Cloud Build and deploy to Cloud Run
# Exam Topics: Cloud Build, cloudbuild.yaml, Artifact Registry, Cloud Run
################################################################################

# ==============================================================================
# CREATE CLOUD BUILD CONFIGURATION FILE
# ==============================================================================

# Create cloudbuild.yaml using heredoc
# cloudbuild.yaml: Defines build steps for Cloud Build
# Exam Tip: Cloud Build executes steps sequentially
cat > cloudbuild.yaml <<EOF
# steps: Array of build steps to execute
steps:
# Step 1: Build Docker image
- name: 'gcr.io/cloud-builders/docker'
  # name: Pre-built Cloud Builder image (contains docker CLI)
  # Available builders: docker, gcloud, npm, maven, gradle, etc.
  # args: Arguments passed to the docker command
  args: [ 'build', '-t', '\${REPO}/sample-node-app-image', '.' ]
  # \${REPO}: Substitution variable (set via --substitutions flag)
  # .: Build context (current directory)
  # Exam Tip: Variables use \${VAR} in cloudbuild.yaml
  
# images: Container images to push to registry after build
images:
- '\${REPO}/sample-node-app-image'
# Automatically pushes image to Artifact Registry or Container Registry
EOF

# ==============================================================================
# CLOUD BUILD EXECUTION
# ==============================================================================

# gcloud builds submit
# Submits source code to Cloud Build for building
# --region: Where to run the build (affects latency and data residency)
# --config: Path to build configuration file (default: cloudbuild.yaml)
# Process: 
#   1. Uploads source code to Cloud Storage
#   2. Executes build steps in containers
#   3. Pushes images to registry
# Exam Tip: Each step runs in a separate container (fresh environment)
# Default timeout: 10 minutes (configurable)
# Pricing: First 120 build-minutes/day free, then per minute
gcloud builds submit --region=$REGION --config=cloudbuild.yaml

# ==============================================================================
# CLOUD RUN DEPLOYMENT
# ==============================================================================

# gcloud run deploy <SERVICE_NAME>
# Deploys container image to Cloud Run
# --image: Image URL from registry (uses $REPO variable)
# --region: Where to deploy the service
# --allow-unauthenticated: Public access without authentication
# Exam Tip: Cloud Build → pushes image → Cloud Run pulls and deploys
# Auto-scaling: From 0 to max instances based on traffic
gcloud run deploy sample-node-app \
  --image ${REPO}/sample-node-app-image \
  --region $REGION \
  --allow-unauthenticated

# ==============================================================================
# VERIFY DEPLOYMENT
# ==============================================================================

# gcloud run services list
# Lists all Cloud Run services in project
# Shows: Service name, region, URL, last deployed time
kubectl run services list

# Example service URL with API endpoint
# Format: https://SERVICE-NAME-PROJECT_NUMBER.REGION.run.app/path
# | jq: Pipe output to jq for JSON formatting (if response is JSON)
# Exam Tip: Cloud Run URLs are HTTPS by default (managed SSL certificates)
https://sample-node-app-981259290698.us-west1.run.app/service/products | jq

################################################################################
# LAB COMPLETE - KEY CONCEPTS REVIEW
################################################################################
#
# 1. Cloud Build Basics:
#    - cloudbuild.yaml: Defines build steps
#    - gcloud builds submit: Starts build process
#    - steps: Array of build operations
#    - Each step runs in isolated container
#
# 2. Cloud Build Steps:
#    - name: Cloud Builder image (docker, gcloud, npm, etc.)
#    - args: Arguments for the builder command
#    - dir: Working directory for the step
#    - env: Environment variables for the step
#
# 3. Cloud Builders:
#    - gcr.io/cloud-builders/docker: Docker commands
#    - gcr.io/cloud-builders/gcloud: gcloud CLI
#    - gcr.io/cloud-builders/npm: Node.js/npm
#    - gcr.io/cloud-builders/mvn: Maven (Java)
#    - gcr.io/cloud-builders/git: Git operations
#
# 4. Images Section:
#    - Lists images to push after successful build
#    - Automatically pushes to configured registry
#    - Can push multiple images from one build
#
# 5. Substitution Variables:
#    - Built-in: $PROJECT_ID, $BUILD_ID, $COMMIT_SHA
#    - Custom: Passed via --substitutions flag
#    - Format: ${VARIABLE_NAME} in cloudbuild.yaml
#
# 6. Cloud Build Features:
#    - Automated triggers (GitHub, Bitbucket, Cloud Source Repos)
#    - Build history and logs
#    - Parallel step execution (with waitFor)
#    - Build artifacts storage
#    - Integration with Cloud Run, GKE, Compute Engine
#
# 7. Best Practices:
#    - Use specific Cloud Builder versions for reproducibility
#    - Cache dependencies to speed up builds
#    - Use substitution variables for flexibility
#    - Set appropriate timeouts for long builds
#    - Store sensitive data in Secret Manager (not cloudbuild.yaml)
#
################################################################################