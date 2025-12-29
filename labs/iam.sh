#!/bin/bash

################################################################################
# GCP IAM and Service Account Authentication Lab
# Purpose: Configure IAM permissions for Cloud Run service invocation
# Exam Topics: IAM, Service Accounts, Cloud Run Authentication, Policy Bindings
################################################################################

# ==============================================================================
# GET BILLING SERVICE URL
# ==============================================================================

# gcloud run services list
# Lists all Cloud Run services in the project
# --format='value(URL)': Extracts only the URL column
# --filter="billing-service": Filters to services matching name "billing-service"
# Exam Tip: Common filters: status.conditions.type, metadata.name, status.url
# Use Case: Retrieve service endpoints for configuration or testing
BILLING_SERVICE_URL=$(gcloud run services list \
  --format='value(URL)' \
  --filter="billing-service")

# ==============================================================================
# DEPLOY AUTHENTICATED BILLING SERVICE
# ==============================================================================

# gcloud run deploy <SERVICE_NAME>
# Redeploy or update existing Cloud Run service
# --image: Pre-built image from Google's registry
# --region: Deployment location (should use $LOCATION variable)
# --no-allow-unauthenticated: Requires authentication to access
# Exam Tip: When updating a service, only changed flags are applied
# Best Practice: Use environment variables for regions and locations
gcloud run deploy billing-service \
  --image gcr.io/qwiklabs-resources/gsp723-parking-service \
  --region $LOCATION \
  --no-allow-unauthenticated

# ==============================================================================
# SERVICE ACCOUNT KEY MANAGEMENT
# ==============================================================================

# gcloud iam service-accounts list
# Lists all service accounts in the project
# --filter="Billing Initiator": Filters by display name
# --format="value(EMAIL)": Extracts only the email address
# Exam Tip: Service account emails format: <SA_NAME>@<PROJECT_ID>.iam.gserviceaccount.com
BILLING_INITIATOR_EMAIL=$(gcloud iam service-accounts list \
  --filter="Billing Initiator" \
  --format="value(EMAIL)"); echo $BILLING_INITIATOR_EMAIL

# gcloud iam service-accounts keys create <OUTPUT_FILE>
# Creates and downloads a JSON key file for a service account
# --iam-account: Service account to create key for
# Security Warning: Keys are sensitive credentials - store securely
# Exam Tip: Keys don't expire by default; rotate regularly
# Best Practice: Use Workload Identity or metadata server instead of keys when possible
# Use Case: Authenticate applications running outside GCP
gcloud iam service-accounts keys create key.json \
  --iam-account=${BILLING_INITIATOR_EMAIL}

# gcloud auth activate-service-account
# Authenticates gcloud using a service account key file
# --key-file: Path to the JSON key file
# Effect: All subsequent gcloud commands run as this service account
# Exam Tip: Use this for CI/CD pipelines, scripts, or testing SA permissions
# Security: Key files grant full access - never commit to version control
gcloud auth activate-service-account --key-file=key.json

# ==============================================================================
# IAM POLICY MANAGEMENT
# ==============================================================================

# gcloud projects remove-iam-policy-binding <PROJECT_ID>
# Removes an IAM role from a member at the project level
# --member: Identity to remove permission from (serviceAccount:EMAIL)
# --role: IAM role to remove (roles/run.invoker)
# Scope: Project-level (broad) - applies to all resources in project
# Exam Tip: IAM bindings can be at: organization, folder, project, or resource level
# Use Case: Clean up overly broad permissions before granting specific ones
gcloud projects remove-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member=serviceAccount:${BILLING_INITIATOR_EMAIL} \
  --role=roles/run.invoker

# gcloud run services add-iam-policy-binding <SERVICE_NAME>
# Grants IAM permission specifically to a Cloud Run service (resource-level)
# --region: Where the service is deployed
# --member: Identity receiving permission
# --role: roles/run.invoker (permission to invoke/call the service)
# --platform managed: Fully managed Cloud Run (vs GKE)
# Exam Tip: Resource-level > Project-level (principle of least privilege)
# Use Case: Allow specific service account to call specific Cloud Run service
# Best Practice: Grant permissions at the most specific level possible
gcloud run services add-iam-policy-binding billing-service \
  --region $LOCATION \
  --member=serviceAccount:${BILLING_INITIATOR_EMAIL} \
  --role=roles/run.invoker \
  --platform managed

################################################################################
# KEY CONCEPTS REVIEW
################################################################################
#
# 1. IAM Hierarchy:
#    - Organization → Folder → Project → Resource
#    - Permissions inherited from parent levels
#    - More specific bindings preferred (least privilege)
#
# 2. Service Account Authentication:
#    - List service accounts: gcloud iam service-accounts list
#    - Create keys: gcloud iam service-accounts keys create
#    - Activate: gcloud auth activate-service-account
#    - Keys are sensitive - never commit to git
#
# 3. IAM Policy Bindings:
#    - Format: member + role + resource
#    - Project-level: gcloud projects add/remove-iam-policy-binding
#    - Resource-level: gcloud <service> add/remove-iam-policy-binding
#    - Always prefer resource-level over project-level
#
# 4. Cloud Run IAM Roles:
#    - roles/run.invoker: Can call the service
#    - roles/run.developer: Can deploy and manage services
#    - roles/run.admin: Full control over Cloud Run
#
# 5. Testing Authentication:
#    - Use identity tokens for Cloud Run: gcloud auth print-identity-token
#    - curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" URL
#
################################################################################