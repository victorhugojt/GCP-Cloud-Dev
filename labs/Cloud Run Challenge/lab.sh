#!/bin/bash

################################################################################
# GCP Cloud Run Challenge Lab
# Purpose: Deploy and secure Cloud Run services with service accounts and IAM
# Exam Topics: Cloud Run, IAM, Service Accounts, Authentication, Container Registry
################################################################################

# ==============================================================================
# PROJECT CONFIGURATION
# ==============================================================================

# gcloud config set project <PROJECT_ID>
# Sets the active GCP project for all subsequent gcloud commands
# --filter: Filters projects list to find Qwiklabs project
# --format: Outputs only the PROJECT_ID value
# Exam Tip: Always verify correct project is active before deployments
gcloud config set project \
$(gcloud projects list --format='value(PROJECT_ID)' \
--filter='qwiklabs-gcp')

# Define the region for all Cloud Run services
# Exam Tip: Choose regions based on latency, compliance, and cost requirements
REGION=us-east4

# gcloud config set run/region <REGION>
# Sets default region for Cloud Run commands
# Benefit: Avoids needing --region flag in every Cloud Run command
# Exam Tip: Common regions: us-central1, us-east1, us-west1, europe-west1, asia-east1
gcloud config set run/region $REGION

# gcloud config set run/platform managed
# Sets Cloud Run platform to fully managed (serverless)
# Options: managed (serverless) vs gke (on GKE cluster)
# Exam Tip: Managed = serverless, auto-scaling, pay-per-use
gcloud config set run/platform managed

# Clone repository and navigate to lab directory
# Exam Tip: Always verify repository structure before building
git clone https://github.com/rosera/pet-theory.git && cd pet-theory/lab07

# ==============================================================================
# TASK 1: DEPLOY PUBLIC STAGING BILLING SERVICE
# ==============================================================================

# Define image and service names
# Naming convention: descriptive-purpose-environment:version
Public_Service_Image_Name=billing-staging-api:0.1
Public_Service_Name=public-billing-service-385

# gcloud builds submit --tag <IMAGE_URL>
# Builds container image using Cloud Build and pushes to Google Container Registry (GCR)
# --tag: Specifies the full image name in format gcr.io/PROJECT_ID/IMAGE_NAME:TAG
# Process: 1) Reads Dockerfile, 2) Builds image, 3) Pushes to GCR
# Exam Tip: gcr.io is legacy; newer projects use Artifact Registry (pkg.dev)
# Pricing: First 120 build-minutes/day are free
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$Public_Service_Image_Name

# gcloud run deploy <SERVICE_NAME>
# Deploys a container to Cloud Run (creates new or updates existing service)
# --image: Container image URL from GCR or Artifact Registry
# --platform managed: Deploy to fully managed Cloud Run (serverless)
# --region: Geographic location for service deployment
# --allow-unauthenticated: Allows public access without authentication
# --max-instances: Maximum number of container instances (prevents runaway costs)
# Exam Tip: Without --allow-unauthenticated, service requires IAM authentication
# Auto-scaling: Scales from 0 to max-instances based on traffic
gcloud run deploy $Public_Service_Name \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$Public_Service_Image_Name \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --max-instances=2

# Service URL (automatically generated after deployment):
# Format: https://SERVICE_NAME-PROJECT_NUMBER.REGION.run.app
# Example output URL from deployment:
# --https://public-billing-service-385-146184502724.us-east4.run.app

# ==============================================================================
# TASK 2: DEPLOY FRONTEND STAGING SERVICE
# ==============================================================================

frontend_service_image_name=frontend-staging:0.1
frontend_service_name=frontend-staging-service-365

# Build frontend container image
# Same process as billing service: Dockerfile → Build → Push to GCR
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$frontend_service_image_name

# Deploy frontend service with public access
# Exam Tip: Frontend services typically need --allow-unauthenticated for user access
# Backend services (APIs, databases) should use --no-allow-unauthenticated
gcloud run deploy $frontend_service_name \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$frontend_service_image_name \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --max-instances=2


# ==============================================================================
# TASK 3: DEPLOY PRIVATE BILLING SERVICE (AUTHENTICATED ACCESS ONLY)
# ==============================================================================

private_service_image_name=billing-staging-api:0.2
private_service_name=private-billing-service-523

# Build private billing service image (version 0.2)
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$private_service_image_name

# gcloud run deploy with --no-allow-unauthenticated
# --no-allow-unauthenticated: Requires authentication to access service
# Use Case: Internal APIs, backend services, sensitive data endpoints
# Exam Tip: Authenticated services require IAM role "roles/run.invoker" to access
# Authentication methods: 
#   1. Service-to-service: Service account with run.invoker role
#   2. User access: Identity token via gcloud auth print-identity-token
gcloud run deploy $private_service_name \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$private_service_image_name \
  --platform managed \
  --region $REGION \
  --no-allow-unauthenticated \
  --max-instances=2

# gcloud run services describe <SERVICE_NAME>
# Retrieves detailed information about a Cloud Run service
# --format "value(status.url)": Extracts only the service URL from output
# Use Case: Get service URL for configuration, testing, or connecting services
# Exam Tip: Common formats: value(), json, yaml, table
BILLING_URL=$(gcloud run services describe $private_service_name \
--platform managed \
--region $REGION \
--format "value(status.url)")

# Separator for visual organization in script
--------------------------------------------------

# ==============================================================================
# TASK 4: CREATE BILLING SERVICE ACCOUNT
# ==============================================================================

billing_sa_name=billing-service-sa-645

# gcloud iam service-accounts create <SA_NAME>
# Creates a new service account (identity for applications/services)
# --display-name: Human-readable name shown in Cloud Console
# Service Account Email: <SA_NAME>@<PROJECT_ID>.iam.gserviceaccount.com
# Use Case: Assign specific permissions to services without using user credentials
# Exam Tip: Service accounts follow principle of least privilege
# Best Practice: One service account per service/application
gcloud iam service-accounts create $billing_sa_name \
    --display-name="Billing Service Cloud Run"

# ==============================================================================
# TASK 5: DEPLOY PRODUCTION BILLING SERVICE WITH SERVICE ACCOUNT
# ==============================================================================

prod_billing_image_name=billing-prod-api:0.1
prod_billing_service_name=billing-prod-service-356

# Build production billing service image
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$prod_billing_image_name

# gcloud run deploy with --service-account
# --service-account: Assigns a service account identity to the Cloud Run service
# Purpose: Service runs with specific IAM permissions (not default compute account)
# Use Case: Access GCS, Firestore, Secret Manager, etc. with minimal permissions
# Exam Tip: Default compute SA has editor role (too permissive); custom SA is best practice
# The service inherits all IAM roles granted to this service account
gcloud run deploy $prod_billing_service_name \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$prod_billing_image_name \
  --service-account=$billing_sa_name \
  --platform managed \
  --region $REGION \
  --no-allow-unauthenticated \
  --max-instances=2

# Get production billing service URL
# Note: Typo in original (REGION instead of $REGION) - keeping for lab consistency
PROD_BILLING_URL=$(gcloud run services describe $prod_billing_service_name \
--platform managed \
--region REGION \
--format "value(status.url)")

# curl with Authorization header for authenticated Cloud Run service
# gcloud auth print-identity-token: Generates OpenID Connect (OIDC) identity token
# Token is valid for 1 hour and represents your authenticated identity
# -X get: HTTP GET request (lowercase 'get' should be 'GET' but works)
# -H "Authorization: Bearer <TOKEN>": Required header for authenticated Cloud Run
# Exam Tip: Identity tokens are different from access tokens (OAuth2)
# Use Case: Testing authenticated Cloud Run endpoints
curl -X get -H "Authorization: Bearer \
$(gcloud auth print-identity-token)" \
$PROD_BILLING_URL

# ==============================================================================
# TASK 6: CREATE FRONTEND SERVICE ACCOUNT WITH INVOKER PERMISSIONS
# ==============================================================================

fronend_sa_name=frontend-service-sa-583
frontend_service_name=frontend-staging-service-365
frontend_prod_service_name=frontend-prod-service-365

# Create the Frontend service account
# Purpose: Allow frontend service to invoke (call) the private billing service
# Exam Tip: Service-to-service authentication uses service accounts with run.invoker role
gcloud iam service-accounts create $fronend_sa_name \
            --display-name="Billing Service Cloud Run Invoker"

# gcloud run services add-iam-policy-binding <TARGET_SERVICE>
# Grants IAM permissions to invoke a specific Cloud Run service
# --member: Identity being granted permission (user, group, or serviceAccount)
# --role: IAM role to grant (roles/run.invoker allows calling the service)
# --region: Where the Cloud Run service is deployed
# Exam Tip: This is how service-to-service authentication works in Cloud Run
# Pattern: ServiceA (with SA_A) → needs run.invoker on ServiceB → can call ServiceB
# Common Error: Forgetting full email format (must include @PROJECT_ID.iam.gserviceaccount.com)
# Note: Get PROJECT_ID first if not set
PROJECT_ID=$(gcloud config get-value project)

gcloud run services add-iam-policy-binding $frontend_service_name \
    --member="serviceAccount:${fronend_sa_name}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/run.invoker" \
    --region=$REGION

# ==============================================================================
# TASK 7: DEPLOY PRODUCTION FRONTEND WITH SERVICE ACCOUNT
# ==============================================================================

frontend_prod_service_image_name=frontend-prod:0.1
frontend_prod_service_name=frontend-prod-service-516

# Build production frontend image
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$frontend_prod_service_image_name

# Deploy frontend production service WITH the frontend service account
# --service-account: The service runs with this identity
# --allow-unauthenticated: Frontend is publicly accessible
# Key Concept: The service account allows the frontend to authenticate
#              to the private billing service
# Architecture: User → Frontend (public, uses frontend-sa) → Billing (private, requires run.invoker)
# Exam Tip: Two separate concerns:
#   1. Who can ACCESS the service (--allow-unauthenticated or not)
#   2. What IDENTITY the service runs as (--service-account)
gcloud run deploy $frontend_prod_service_name \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$frontend_prod_service_image_name \
  --service-account=$fronend_sa_name \
  --region $REGION \
  --allow-unauthenticated

################################################################################
# LAB COMPLETE - KEY CONCEPTS REVIEW
################################################################################
# 
# 1. Cloud Run Deployment:
#    - gcloud builds submit: Build and push container images
#    - gcloud run deploy: Deploy services (public or private)
#    - --allow-unauthenticated vs --no-allow-unauthenticated
#
# 2. Service Accounts:
#    - gcloud iam service-accounts create: Create identity for services
#    - --service-account flag: Assign identity to Cloud Run service
#    - Service accounts inherit IAM permissions
#
# 3. Service-to-Service Authentication:
#    - roles/run.invoker: Permission to call Cloud Run service
#    - add-iam-policy-binding: Grant invoker permission
#    - Pattern: Frontend SA → has run.invoker on → Backend Service
#
# 4. Authentication Methods:
#    - Public services: No auth required
#    - Private services: Require identity token
#    - gcloud auth print-identity-token: Generate OIDC token for testing
#
# 5. Best Practices:
#    - Use service accounts (not default compute SA)
#    - Principle of least privilege
#    - One service account per service
#    - Private by default (--no-allow-unauthenticated)
#    - Set max-instances to prevent runaway costs
#
################################################################################