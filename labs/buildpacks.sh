#!/bin/bash

################################################################################
# Cloud Buildpacks - Direct Deploy from Source
# Purpose: Deploy applications to Cloud Run without writing Dockerfiles
# Exam Topics: Buildpacks, Cloud Run, Source-based deployment, API enablement
################################################################################

# ==============================================================================
# PROJECT CONFIGURATION
# ==============================================================================

# Get current project ID
PROJECT_ID=$(gcloud config get-value project)
REGION=us-east4

# ==============================================================================
# ENABLE REQUIRED APIs
# ==============================================================================

# gcloud services enable <API_NAMES>
# Enable multiple APIs simultaneously
# artifactregistry.googleapis.com: For storing container images
# run.googleapis.com: For Cloud Run deployments
# translate.googleapis.com: For Cloud Translation API (if app uses it)
# Exam Tip: Buildpacks automatically use Artifact Registry (not gcr.io)
gcloud services enable artifactregistry.googleapis.com \
  run.googleapis.com \
  translate.googleapis.com

# ==============================================================================
# DOWNLOAD AND EXTRACT SAMPLE APPLICATION
# ==============================================================================

# gcloud storage cp gs://<BUCKET>/<OBJECT> <DESTINATION>
# Downloads file from Cloud Storage
# &&: Runs next command only if previous succeeds
# unzip: Extracts the zip archive
# Exam Tip: Cloud Storage buckets with gs:// prefix
gcloud storage cp gs://cloud-training/CBL513/sample-apps/sample-py-app.zip . \
  && unzip sample-py-app

# ==============================================================================
# DEPLOY WITH BUILDPACKS (NO DOCKERFILE NEEDED)
# ==============================================================================

# gcloud run deploy <SERVICE_NAME> --source <DIRECTORY>
# Deploys application directly from source code using Cloud Buildpacks
# --source .: Uses current directory as source
# Process:
#   1. Auto-detects language (Python, Node.js, Go, Java, .NET)
#   2. Builds container image with best practices
#   3. Pushes image to Artifact Registry
#   4. Deploys to Cloud Run
# --region: Where to deploy the service
# --allow-unauthenticated: Public access
# Exam Tip: No Dockerfile required - buildpacks handle everything
# Supported languages: Python, Node.js, Go, Java, .NET Core
# Use Case: Fast deployment for standard applications
gcloud run deploy sample-py-app \
  --source . \
  --region=$REGION \
  --allow-unauthenticated

################################################################################
# LAB COMPLETE - KEY CONCEPTS REVIEW
################################################################################
#
# 1. Cloud Buildpacks:
#    - Auto-detects programming language
#    - Builds OCI-compliant container images
#    - No Dockerfile required
#    - Follows best practices automatically
#    - Based on Cloud Native Buildpacks (CNCF project)
#
# 2. Buildpacks vs Dockerfile:
#    - Buildpacks: Automatic, faster to start, standard approach
#    - Dockerfile: Full control, custom base images, complex setups
#    - Use buildpacks for: Standard apps, rapid prototyping
#    - Use Dockerfile for: Custom requirements, multi-stage builds
#
# 3. Language Detection:
#    - Python: Looks for requirements.txt, setup.py, Pipfile
#    - Node.js: Looks for package.json
#    - Go: Looks for go.mod
#    - Java: Looks for pom.xml, build.gradle
#    - .NET: Looks for *.csproj files
#
# 4. Source-based Deployment Benefits:
#    - Faster onboarding (no Docker knowledge needed)
#    - Consistent builds across team
#    - Automatic security updates
#    - Built-in best practices
#    - Reduced maintenance
#
# 5. Behind the Scenes:
#    - Creates temporary Artifact Registry repository (if needed)
#    - Builds image using buildpacks
#    - Tags image with commit SHA
#    - Pushes to Artifact Registry
#    - Deploys to Cloud Run
#
################################################################################