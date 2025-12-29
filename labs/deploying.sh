#!/bin/bash

################################################################################
# GCP Full Stack Application Deployment Lab
# Purpose: Deploy a complete web application with Firestore, Storage, Secrets, and Cloud Run
# Exam Topics: Firestore, Cloud Storage, Secret Manager, Artifact Registry, IAM, Cloud Run
################################################################################

# ==============================================================================
# DATABASE SETUP - FIRESTORE
# ==============================================================================

# gcloud firestore databases create
# Creates a Firestore database in Native mode
# --location: Geographic location for data storage
# Native mode: Document-oriented NoSQL database, real-time updates, offline support
# vs Datastore mode: Backwards compatible with Datastore, no real-time features
# Exam Tip: Location is permanent and affects latency and compliance
# Use Case: Web/mobile apps needing real-time sync and offline capabilities
gcloud firestore databases create --location=europe-west1

# ==============================================================================
# STORAGE SETUP - CLOUD STORAGE BUCKET
# ==============================================================================

# gcloud storage buckets create gs://<BUCKET_NAME>
# Creates a Cloud Storage bucket for storing files (images, videos, documents)
# --location: Geographic location (single region, dual-region, or multi-region)
# --no-public-access-prevention: Allows making objects public (not recommended for sensitive data)
# --uniform-bucket-level-access: Uses IAM only (not ACLs) for permissions
# Exam Tip: Bucket names must be globally unique across all GCP
# Naming: Use project ID in name to ensure uniqueness
# Use Case: Store user-uploaded files, static assets, backups
gcloud storage buckets create gs://${GOOGLE_CLOUD_PROJECT}-covers \
  --location=europe-west1 \
  --no-public-access-prevention \
  --uniform-bucket-level-access

# gcloud storage buckets add-iam-policy-binding gs://<BUCKET>
# Grants IAM permissions on a bucket
# --member=allUsers: Public access (anyone on the internet)
# --role=roles/storage.legacyObjectReader: Can read objects but not list or modify
# Exam Tip: roles/storage.objectViewer = read objects + list bucket
#           roles/storage.objectCreator = upload objects
#           roles/storage.objectAdmin = full control
# Security Warning: allUsers makes objects publicly accessible
gcloud storage buckets add-iam-policy-binding \
  gs://${GOOGLE_CLOUD_PROJECT}-covers \
  --member=allUsers \
  --role=roles/storage.legacyObjectReader

# ==============================================================================
# SECRET MANAGEMENT - SECRET MANAGER
# ==============================================================================

# gcloud services enable secretmanager.googleapis.com
# Enables the Secret Manager API in the project
# Secret Manager: Securely store API keys, passwords, certificates
# Exam Tip: APIs must be enabled before use (some enable automatically)
# Billing: Charged per secret version per month + per access operation
gcloud services enable secretmanager.googleapis.com

# Move and rename OAuth client secret file
# Standardizes filename for application configuration
mv ~/client_secret*.json ~/client_secret.json

# gcloud secrets create <SECRET_NAME>
# Creates a new secret in Secret Manager
# --data-file: Upload secret value from a file
# Exam Tip: Secrets are versioned; you can have multiple versions
# Use Case: Store OAuth credentials, database passwords, API keys
# Best Practice: Never hardcode secrets in source code or environment variables
gcloud secrets create bookshelf-client-secrets \
  --data-file=$HOME/client_secret.json

# Generate random 20-character string and store as secret
# tr -dc A-Za-z0-9: Generate alphanumeric characters only
# </dev/urandom: Read from random number generator
# head -c 20: Take first 20 characters
# --data-file=-: Read from stdin (pipe)
# Use Case: Generate Flask session secret key for secure cookie signing
# Exam Tip: Random secrets should be cryptographically secure
tr -dc A-Za-z0-9 </dev/urandom | head -c 20 | \
  gcloud secrets create flask-secret-key --data-file=-

# ==============================================================================
# LOCAL TESTING - RUN APPLICATION LOCALLY
# ==============================================================================

# Run Flask application locally using gunicorn
# cd ~/bookshelf: Change to application directory
# EXTERNAL_HOST_URL: Environment variable for OAuth callback
# ~/.local/bin/gunicorn: WSGI HTTP server for Python
# -b :8080: Bind to port 8080 on all interfaces
# main:app: Module 'main', WSGI application object 'app'
# Exam Tip: Cloud Shell exposes ports via web preview (not direct IP)
# Use Case: Test application before deploying to Cloud Run
cd ~/bookshelf; EXTERNAL_HOST_URL="https://8080-${WEB_HOST}" \
  ~/.local/bin/gunicorn -b :8080 main:app

# ==============================================================================
# CONTAINER REGISTRY - ARTIFACT REGISTRY
# ==============================================================================

# gcloud artifacts repositories create <REPO_NAME>
# Creates a repository in Artifact Registry (newer than Container Registry)
# --repository-format=docker: Store Docker/OCI container images
# --location: Regional location (affects latency and compliance)
# Artifact Registry vs Container Registry (gcr.io):
#   - Artifact Registry: Newer, more features, supports multiple formats
#   - Container Registry: Legacy, Docker only, uses gcr.io domain
# Exam Tip: New projects should use Artifact Registry
# Formats: docker, maven, npm, python, apt, yum
gcloud artifacts repositories create app-repo \
  --repository-format=docker \
  --location=europe-west1

# gcloud artifacts repositories describe <REPO_NAME>
# Shows details about an Artifact Registry repository
# --location: Where the repository is located
# Use Case: Verify repository creation, get repository URL
gcloud artifacts repositories describe app-repo \
  --location=europe-west1

# ==============================================================================
# BUILD AND PUSH CONTAINER - BUILDPACKS
# ==============================================================================

# gcloud builds submit
# Builds a container image using Cloud Build
# --pack: Use Cloud Native Buildpacks (auto-detects language, no Dockerfile needed)
# --image: Destination image URL in Artifact Registry
# Format: <LOCATION>-docker.pkg.dev/<PROJECT>/<REPO>/<IMAGE>
# Exam Tip: Buildpacks vs Dockerfile:
#   - Buildpacks: Automatic, follows best practices, no Dockerfile
#   - Dockerfile: Full control, custom configuration
# Use Case: Python, Node.js, Java, Go apps without writing Dockerfile
# Process: 1) Detect language, 2) Install dependencies, 3) Build image, 4) Push to registry
gcloud builds submit \
  --pack image=europe-west1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/app-repo/bookshelf \
  ~/bookshelf

# gcloud builds list
# Lists Cloud Build history in the project
# Shows: Build ID, create time, duration, status, source
# Exam Tip: Useful for troubleshooting failed builds
gcloud builds list

# ==============================================================================
# INITIAL CLOUD RUN DEPLOYMENT
# ==============================================================================

# gcloud run deploy <SERVICE_NAME>
# Deploys container to Cloud Run (creates new or updates existing service)
# --image: Container image from Artifact Registry
# --region: Geographic location for service
# --allow-unauthenticated: Public access without authentication
# --update-env-vars: Set environment variables for the container
# Exam Tip: Environment variables are visible in console/describe command
# Use Secret Manager for sensitive values (--update-secrets)
# Auto-scaling: 0 to 1000 instances by default (configurable)
gcloud run deploy bookshelf \
  --image=europe-west1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/app-repo/bookshelf \
  --region=europe-west1 \
  --allow-unauthenticated \
  --update-env-vars=GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT}

# Generate and display Cloud Run service URL
# gcloud projects describe: Get project metadata
# --format="value(projectNumber)": Extract numeric project number
# URL Format: https://<SERVICE>-<PROJECT_NUMBER>.<REGION>.run.app
# Exam Tip: Service URLs are stable and don't change unless service is deleted
echo "https://bookshelf-$(gcloud projects describe $GOOGLE_CLOUD_PROJECT \
  --format="value(projectNumber)").europe-west1.run.app"

# ==============================================================================
# SERVICE ACCOUNT CREATION WITH IAM ROLES
# ==============================================================================

# gcloud iam service-accounts create <SA_NAME>
# Creates service account for the Cloud Run service
# Best Practice: Dedicated service account per service (not default compute SA)
# Naming: Descriptive name indicating purpose
gcloud iam service-accounts create bookshelf-run-sa

# gcloud projects add-iam-policy-binding <PROJECT_ID>
# Grants IAM roles at project level
# --member="serviceAccount:<EMAIL>": Service account identity
# --role: Predefined or custom IAM role

# Role: roles/secretmanager.secretAccessor
# Permission: Read secret values from Secret Manager
# Use Case: Allow app to retrieve OAuth credentials and Flask secret key
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:bookshelf-run-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Role: roles/cloudtranslate.user
# Permission: Use Cloud Translation API
# Use Case: Translate book titles/descriptions to different languages
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:bookshelf-run-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/cloudtranslate.user"

# Role: roles/datastore.user
# Permission: Read/write to Firestore/Datastore
# Use Case: Store and retrieve book records from database
# Exam Tip: datastore.user works for both Firestore Native and Datastore mode
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:bookshelf-run-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/datastore.user"

# Role: roles/storage.objectUser
# Permission: Read/write objects in Cloud Storage
# Use Case: Upload book cover images, retrieve user-uploaded files
# Exam Tip: objectUser = objectViewer + objectCreator (read + write)
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:bookshelf-run-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/storage.objectUser"


# ==============================================================================
# REDEPLOY WITH SERVICE ACCOUNT
# ==============================================================================

# Redeploy Cloud Run service with service account
# --service-account: Assigns custom service account to the service
# Effect: Service runs with permissions defined by SA's IAM roles
# Exam Tip: Redeployment triggers new revision; old revisions remain available
# Use Case: Update service to use least-privilege service account
gcloud run deploy bookshelf \
  --image=europe-west1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/app-repo/bookshelf \
  --region=europe-west1 \
  --allow-unauthenticated \
  --update-env-vars=GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT} \
  --service-account=bookshelf-run-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com

# Display service URLs for configuration
echo "https://bookshelf-$(gcloud projects describe $GOOGLE_CLOUD_PROJECT \
  --format="value(projectNumber)").europe-west1.run.app"

# Display domain for OAuth configuration (without https://)
echo "bookshelf-$(gcloud projects describe $GOOGLE_CLOUD_PROJECT \
  --format="value(projectNumber)").europe-west1.run.app"

# Display OAuth callback URL for OAuth consent screen configuration
# Use Case: Configure in Google Cloud Console OAuth consent screen
echo "https://bookshelf-$(gcloud projects describe $GOOGLE_CLOUD_PROJECT \
  --format="value(projectNumber)").europe-west1.run.app/oauth2callback"

# ==============================================================================
# ERROR REPORTING IAM ROLE
# ==============================================================================

# Role: roles/errorreporting.writer
# Permission: Write error reports to Cloud Error Reporting
# Use Case: Application can log exceptions and errors for monitoring
# Exam Tip: Error Reporting aggregates and displays application errors
# Best Practice: Add this role to catch and track production issues
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:bookshelf-run-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/errorreporting.writer"

################################################################################
# LAB COMPLETE - KEY CONCEPTS REVIEW
################################################################################
#
# 1. Service Stack Setup:
#    - Firestore: NoSQL database for application data
#    - Cloud Storage: Object storage for files and media
#    - Secret Manager: Secure storage for credentials
#    - Artifact Registry: Container image repository
#    - Cloud Run: Serverless container execution
#
# 2. Build and Deploy:
#    - Buildpacks: No Dockerfile needed, auto-detects language
#    - Cloud Build: Managed build service
#    - Artifact Registry: Modern alternative to Container Registry
#
# 3. Service Account IAM Roles:
#    - secretmanager.secretAccessor: Read secrets
#    - cloudtranslate.user: Use Translation API
#    - datastore.user: Access Firestore/Datastore
#    - storage.objectUser: Read/write Cloud Storage
#    - errorreporting.writer: Write error logs
#
# 4. Security Best Practices:
#    - Use Secret Manager for credentials (not env vars)
#    - Create dedicated service accounts per service
#    - Grant minimum necessary permissions (least privilege)
#    - Never commit secrets to source control
#
# 5. Cloud Run Features:
#    - Auto-scaling from 0 to max instances
#    - Pay only for actual usage (per 100ms)
#    - Environment variables for configuration
#    - Service account for identity and permissions
#    - Stable HTTPS URLs automatically provided
#
################################################################################