#!/bin/bash

################################################################################
# Gemini AI Integration with Cloud Run Lab
# Purpose: Deploy Streamlit app with Gemini AI to Cloud Run
# Exam Topics: Cloud Run, Vertex AI, Gemini, Artifact Registry, API Enablement
################################################################################

# ==============================================================================
# PROJECT SETUP AND CONFIGURATION
# ==============================================================================

# Get current project ID from gcloud configuration
# gcloud config get-value project: Returns active project ID
# Exam Tip: Always verify correct project before deployments
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
echo "PROJECT_ID=${PROJECT_ID}"
echo "REGION=${REGION}"

# ==============================================================================
# ENABLE REQUIRED GOOGLE CLOUD APIS
# ==============================================================================

# gcloud services enable <API_NAME>
# Enables multiple APIs in one command (space-separated)
# Exam Tip: APIs must be enabled before use; some auto-enable dependencies
# cloudbuild.googleapis.com: Cloud Build for container image building
# cloudfunctions.googleapis.com: Cloud Functions (if needed for event triggers)
# run.googleapis.com: Cloud Run for deploying containers
# logging.googleapis.com: Cloud Logging for application logs
# storage-component.googleapis.com: Cloud Storage for file storage
# aiplatform.googleapis.com: Vertex AI for Gemini and ML models
# Use Case: Enable all required services before deployment
# Pricing: Most APIs free, usage-based charges apply for requests
gcloud services enable cloudbuild.googleapis.com \
  cloudfunctions.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  storage-component.googleapis.com \
  aiplatform.googleapis.com

# ==============================================================================
# LOCAL TESTING - STREAMLIT APPLICATION
# ==============================================================================

# streamlit run <APP_FILE>
# Runs Streamlit web application locally
# --browser.serverAddress=localhost: Listen on localhost
# --server.enableCORS=false: Disable CORS (for local testing)
# --server.enableXsrfProtection=false: Disable XSRF (for local testing)
# --server.port 8080: Port to listen on
# Exam Tip: Streamlit is Python framework for data/ML web apps
# Use Case: Test application before deploying to Cloud Run
streamlit run app.py \
--browser.serverAddress=localhost \
--server.enableCORS=false \
--server.enableXsrfProtection=false \
--server.port 8080

# ==============================================================================
# DEFINE SERVICE AND REPOSITORY NAMES
# ==============================================================================

# Service name for Cloud Run
SERVICE_NAME='gemini-app-playground'
# Repository name in Artifact Registry
AR_REPO='gemini-app-repo'
echo "SERVICE_NAME=${SERVICE_NAME}"
echo "AR_REPO=${AR_REPO}"

# ==============================================================================
# ARTIFACT REGISTRY SETUP
# ==============================================================================

# gcloud artifacts repositories create <REPO_NAME>
# Creates Artifact Registry repository for Docker images
# --location: Regional location
# --repository-format=Docker: Store Docker/OCI container images
# Exam Tip: Artifact Registry > Container Registry (newer, more features)
gcloud artifacts repositories create "$AR_REPO" \
  --location="$REGION" \
  --repository-format=Docker

# gcloud auth configure-docker <REGISTRY_URL>
# Configures Docker to authenticate with Artifact Registry
# Format: <REGION>-docker.pkg.dev for Artifact Registry
# Effect: Adds credential helper to Docker config
# Exam Tip: Must run before pushing images to registry
gcloud auth configure-docker "$REGION-docker.pkg.dev"

# ==============================================================================
# CREATE DOCKERFILE FOR STREAMLIT APP
# ==============================================================================

# Create Dockerfile using heredoc
cat > ~/gemini-app/Dockerfile <<EOF
# FROM python:3.8
# Base image with Python 3.8
# Exam Tip: Use specific versions for reproducibility
FROM python:3.8

# EXPOSE 8080
# Documents port that container listens on
# Cloud Run requires port 8080 by default (configurable)
EXPOSE 8080

# WORKDIR /app
# Sets working directory inside container
WORKDIR /app

# COPY . ./
# Copies application files from build context to container
COPY . ./

# RUN pip install -r requirements.txt
# Installs Python dependencies during image build
# requirements.txt: Lists Python packages needed
RUN pip install -r requirements.txt

# ENTRYPOINT: Command that always runs when container starts
# streamlit run app.py: Start Streamlit server
# --server.port=8080: Listen on port 8080
# --server.address=0.0.0.0: Listen on all network interfaces
# Exam Tip: ENTRYPOINT vs CMD - ENTRYPOINT is harder to override
ENTRYPOINT ["streamlit", "run", "app.py", "--server.port=8080", "--server.address=0.0.0.0"]

EOF

# ==============================================================================
# BUILD AND PUSH CONTAINER IMAGE
# ==============================================================================

# gcloud builds submit --tag <IMAGE_URL>
# Builds container image using Cloud Build and pushes to Artifact Registry
# --tag: Full image URL in Artifact Registry
# Format: <REGION>-docker.pkg.dev/<PROJECT>/<REPO>/<IMAGE>
# Process: Uploads code → Builds image → Pushes to registry
# Exam Tip: Reads Dockerfile from current directory by default
gcloud builds submit --tag "$REGION-docker.pkg.dev/$PROJECT_ID/$AR_REPO/$SERVICE_NAME"

# ==============================================================================
# DEPLOY TO CLOUD RUN
# ==============================================================================

# gcloud run deploy <SERVICE_NAME>
# Deploys container to Cloud Run
# --port=8080: Container port to send requests to
# --image: Container image URL from Artifact Registry
# --allow-unauthenticated: Public access (no authentication required)
# --region: Geographic location for service
# --platform=managed: Fully managed Cloud Run (serverless)
# --project: GCP project ID
# --set-env-vars: Environment variables passed to container
#   PROJECT_ID: Used by app to access Vertex AI
#   REGION: Used by app to access regional Vertex AI endpoint
# Exam Tip: Environment variables visible in console; use Secrets for sensitive data
# Auto-scaling: 0 to 1000 instances by default
gcloud run deploy "$SERVICE_NAME" \
  --port=8080 \
  --image="$REGION-docker.pkg.dev/$PROJECT_ID/$AR_REPO/$SERVICE_NAME" \
  --allow-unauthenticated \
  --region=$REGION \
  --platform=managed  \
  --project=$PROJECT_ID \
  --set-env-vars=PROJECT_ID=$PROJECT_ID,REGION=$REGION

################################################################################
# LAB COMPLETE - KEY CONCEPTS REVIEW
################################################################################
#
# 1. Gemini AI Integration:
#    - Vertex AI Platform: Google's unified ML platform
#    - aiplatform.googleapis.com: API for Gemini and other models
#    - Environment variables: PROJECT_ID and REGION for API calls
#    - Use Case: Chat applications, code generation, content creation
#
# 2. Streamlit Framework:
#    - Python framework for data/ML web applications
#    - Rapid prototyping with simple Python syntax
#    - Built-in widgets for user interaction
#    - Streamlit Cloud vs Cloud Run: Cloud Run gives full control
#
# 3. Dockerfile Best Practices:
#    - Use specific Python version (not :latest)
#    - EXPOSE documents the port
#    - WORKDIR sets working directory
#    - COPY brings application code
#    - RUN installs dependencies
#    - ENTRYPOINT defines startup command
#
# 4. Cloud Run Configuration:
#    - --port: Must match EXPOSE in Dockerfile
#    - --allow-unauthenticated: For public access
#    - --set-env-vars: Pass configuration to container
#    - Platform: managed (serverless) vs gke (on GKE)
#
# 5. API Enablement:
#    - Always enable required APIs before use
#    - cloudbuild: Build containers
#    - run: Deploy to Cloud Run
#    - aiplatform: Access Gemini/Vertex AI
#    - logging: Application logs
#
# 6. Development Workflow:
#    - Local testing: streamlit run app.py
#    - Build image: gcloud builds submit
#    - Deploy: gcloud run deploy
#    - Update: Redeploy with same command (creates new revision)
#
################################################################################