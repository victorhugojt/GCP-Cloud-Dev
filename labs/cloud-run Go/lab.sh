#!/bin/bash

################################################################################
# Go REST API with Firestore on Cloud Run
# Purpose: Deploy Go application with Firestore database to Cloud Run
# Exam Topics: Cloud Run, Firestore, Go, Cloud Storage, Data Import
################################################################################

# ==============================================================================
# PROJECT CONFIGURATION
# ==============================================================================

# Set project to Qwiklabs project automatically
# Filters projects list to find the Qwiklabs GCP project
gcloud config set project \
  $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')

# ==============================================================================
# BUILD GO APPLICATION
# ==============================================================================

# go build -o <OUTPUT_FILE>
# Compiles Go source code into executable binary
# -o server: Output file name (executable)
# Exam Tip: Go compiles to single binary (no runtime dependencies)
# Use Case: Build before containerizing or running locally
go build -o server

# ==============================================================================
# BUILD AND PUSH CONTAINER IMAGE
# ==============================================================================

# gcloud builds submit --tag <IMAGE_URL>
# Builds container image using Cloud Build (reads Dockerfile)
# Version 0.1: Initial version
# Exam Tip: Using gcr.io (Container Registry)
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1

# ==============================================================================
# DEPLOY TO CLOUD RUN - VERSION 0.1
# ==============================================================================

# gcloud run deploy <SERVICE_NAME>
# Deploys Go REST API to Cloud Run
# --image: Container image with version tag
# --platform managed: Fully managed serverless
# --region: Deployment location
# --allow-unauthenticated: Public access
# --max-instances=2: Limit concurrent instances
# Exam Tip: Go apps typically have fast cold starts
gcloud run deploy rest-api \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1 \
  --platform managed \
  --region us-east4 \
  --allow-unauthenticated \
  --max-instances=2

# ==============================================================================
# CREATE CLOUD STORAGE BUCKET
# ==============================================================================

# gsutil mb -c <STORAGE_CLASS> -l <LOCATION> gs://<BUCKET_NAME>
# Creates a Cloud Storage bucket
# mb: Make bucket
# -c standard: Storage class (standard, nearline, coldline, archive)
# -l us-east4: Location (must match Cloud Run region for low latency)
# Bucket name: PROJECT_ID-customer (ensures uniqueness)
# Exam Tip: Storage classes affect cost and access patterns
#   - Standard: Frequent access
#   - Nearline: Access < once/month
#   - Coldline: Access < once/quarter
#   - Archive: Long-term archival
gsutil mb -c standard -l us-east4 gs://$GOOGLE_CLOUD_PROJECT-customer

# ==============================================================================
# COPY FIRESTORE EXPORT TO BUCKET
# ==============================================================================

# gsutil cp -r gs://<SOURCE> gs://<DESTINATION>
# Copies Firestore export data to your bucket
# -r: Recursive (copy directory and contents)
# Source: Pre-made Firestore export from training bucket
# Use Case: Import existing Firestore data
# Exam Tip: Firestore exports are timestamped directories
gsutil cp -r gs://spls/gsp645/2019-10-06T20:10:37_43617 \
  gs://$GOOGLE_CLOUD_PROJECT-customer

# ==============================================================================
# IMPORT DATA TO FIRESTORE
# ==============================================================================

# gcloud beta firestore import gs://<BUCKET>/<EXPORT_DIR>
# Imports Firestore data from Cloud Storage export
# beta: Feature is in beta (may change)
# import: Restores collections and documents
# Exam Tip: Must be full path to timestamped export directory
# Use Case: Migrate data, restore backups, populate database
# Requirements: 
#   - Firestore database must exist
#   - Export must be in same project or accessible
gcloud beta firestore import \
  gs://$GOOGLE_CLOUD_PROJECT-customer/2019-10-06T20:10:37_43617/

# ==============================================================================
# BUILD VERSION 0.2 (WITH FIRESTORE INTEGRATION)
# ==============================================================================

# Build new version of application (presumably with Firestore code changes)
# Version 0.2: Updated to read from Firestore
# Exam Tip: Use semantic versioning for tracking changes
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2

################################################################################
# LAB COMPLETE - KEY CONCEPTS REVIEW
################################################################################
#
# 1. Go on Cloud Run:
#    - Fast cold starts (compiled binary)
#    - Small container images
#    - Excellent for APIs and microservices
#    - Native support for HTTP/2 and gRPC
#
# 2. Firestore Database:
#    - NoSQL document database
#    - Native mode vs Datastore mode
#    - Real-time updates and offline support
#    - Hierarchical: Collections → Documents → Subcollections
#    - Exam Tip: Choose location carefully (permanent decision)
#
# 3. Firestore Import/Export:
#    - Export: gcloud firestore export gs://bucket
#    - Import: gcloud firestore import gs://bucket/export-dir
#    - Use Case: Backups, migrations, data seeding
#    - Timestamped exports allow point-in-time recovery
#
# 4. Cloud Storage Integration:
#    - gsutil mb: Create bucket
#    - gsutil cp: Copy files/directories
#    - Storage classes: standard, nearline, coldline, archive
#    - Location should match compute resources (lower latency)
#
# 5. Versioning Strategy:
#    - Tag images with versions (0.1, 0.2, etc.)
#    - Allows rollback to previous versions
#    - Traffic splitting between versions
#    - Blue/green deployments
#
# 6. Cloud Run Revisions:
#    - Each deployment creates new revision
#    - Can route traffic to specific revisions
#    - Can rollback by routing to previous revision
#    - Revisions are immutable
#
# 7. Best Practices:
#    - Version your container images
#    - Match storage location to compute region
#    - Set max-instances to control costs
#    - Use semantic versioning (major.minor.patch)
#    - Regular Firestore backups (exports)
#
################################################################################