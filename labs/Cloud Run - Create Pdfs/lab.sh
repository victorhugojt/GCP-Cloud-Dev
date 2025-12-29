#!/bin/bash

################################################################################
# Event-Driven PDF Conversion with Cloud Run and Pub/Sub
# Purpose: Create PDF converter triggered by Cloud Storage uploads via Pub/Sub
# Exam Topics: Cloud Run, Pub/Sub, Cloud Storage, Event-driven architecture, IAM
################################################################################

# ==============================================================================
# AUTHENTICATION AND SETUP
# ==============================================================================

# gcloud auth list --filter=status:ACTIVE --format="value(account)"
# Lists currently active authenticated account
# --filter: Only show ACTIVE accounts
# --format: Output only the account email
# Use Case: Verify correct account is active before proceeding
gcloud auth list --filter=status:ACTIVE --format="value(account)"

# ==============================================================================
# ENABLE REQUIRED API
# ==============================================================================

# cloudaicompanion.googleapis.com: Cloud AI Companion API
# (Formerly called Cloud Code or Duet AI)
# Exam Tip: Some labs require specific APIs for certain features
gcloud services enable cloudaicompanion.googleapis.com

# ==============================================================================
# BUILD CONTAINER IMAGE
# ==============================================================================

# gcloud builds submit --tag <IMAGE_URL>
# Builds PDF converter container using Dockerfile
# Format: gcr.io/<PROJECT_ID>/<IMAGE_NAME>
# Exam Tip: Using gcr.io (Container Registry) instead of Artifact Registry
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter

# ==============================================================================
# DEPLOY CLOUD RUN SERVICE WITH CUSTOM CONFIGURATION
# ==============================================================================

# gcloud run deploy <SERVICE_NAME>
# Deploy PDF converter service with specific resource requirements
# --image: Container image from Container Registry
# --platform managed: Fully managed Cloud Run
# --region: Deployment location
# --memory=2Gi: Allocate 2 GiB memory (PDF processing is memory-intensive)
# --no-allow-unauthenticated: Requires authentication (only Pub/Sub can invoke)
# --set-env-vars: Environment variables for the container
#   PDF_BUCKET: Where to store converted PDFs
# --max-instances=3: Limit concurrent instances (cost control)
# Exam Tip: Memory options: 128Mi, 256Mi, 512Mi, 1Gi, 2Gi, 4Gi, 8Gi
# Use Case: Process-heavy workloads need more memory
gcloud run deploy pdf-converter \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter \
  --platform managed \
  --region us-east4 \
  --memory=2Gi \
  --no-allow-unauthenticated \
  --set-env-vars PDF_BUCKET=$GOOGLE_CLOUD_PROJECT-processed \
  --max-instances=3

# ==============================================================================
# CLOUD STORAGE NOTIFICATION SETUP
# ==============================================================================

# gsutil notification create -t <TOPIC> -f <FORMAT> -e <EVENT> gs://<BUCKET>
# Creates a Pub/Sub notification for Cloud Storage events
# -t new-doc: Pub/Sub topic name (auto-created if doesn't exist)
# -f json: Notification payload format
# -e OBJECT_FINALIZE: Trigger when object upload completes
# Effect: When file uploaded to bucket → Pub/Sub message published
# Exam Tip: Other events: OBJECT_DELETE, OBJECT_ARCHIVE, OBJECT_METADATA_UPDATE
# Use Case: Event-driven processing of uploaded files
gsutil notification create -t new-doc \
  -f json \
  -e OBJECT_FINALIZE \
  gs://$GOOGLE_CLOUD_PROJECT-upload

# ==============================================================================
# SERVICE ACCOUNT FOR PUB/SUB TO CLOUD RUN
# ==============================================================================

# Create service account for Pub/Sub to invoke Cloud Run
# --display-name: Human-readable name
# Use Case: Pub/Sub needs identity to authenticate to Cloud Run
gcloud iam service-accounts create pubsub-cloud-run-invoker \
  --display-name "PubSub Cloud Run Invoker"

# gcloud run services add-iam-policy-binding <SERVICE_NAME>
# Grant run.invoker role to service account on pdf-converter service
# --member: Service account that gets permission
# --role: roles/run.invoker (permission to call the service)
# --region: Where service is deployed
# --platform managed: Cloud Run type
# Exam Tip: This allows Pub/Sub to trigger Cloud Run service
gcloud run services add-iam-policy-binding pdf-converter \
  --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
  --role=roles/run.invoker \
  --region us-east4 \
  --platform managed

# ==============================================================================
# GET PROJECT NUMBER
# ==============================================================================

# Get numeric project number (different from project ID)
# --format: Extract only PROJECT_NUMBER
# --filter: Filter to current project
# Exam Tip: Project number is numeric, project ID is string
PROJECT_NUMBER=$(gcloud projects list \
  --format="value(PROJECT_NUMBER)" \
  --filter="$GOOGLE_CLOUD_PROJECT")

# ==============================================================================
# SERVICE ACCOUNT TOKEN CREATOR ROLE
# ==============================================================================

# gcloud projects add-iam-policy-binding <PROJECT_ID>
# Grant serviceAccountTokenCreator role
# --member: Service account needing token creation permission
# --role: roles/iam.serviceAccountTokenCreator
# Use Case: Allows service account to create tokens for authentication
# Exam Tip: Required for Pub/Sub push subscriptions with authentication
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member=serviceAccount:qwiklabs-gcp-01-d97271f75737@qwiklabs-gcp-01-d97271f75737.iam.gserviceaccount.com \
  --role=roles/iam.serviceAccountTokenCreator

# ==============================================================================
# CREATE PUB/SUB PUSH SUBSCRIPTION
# ==============================================================================

# gcloud pubsub subscriptions create <SUBSCRIPTION_NAME>
# Creates push subscription to invoke Cloud Run
# --topic: Pub/Sub topic to subscribe to
# --push-endpoint: Cloud Run service URL (must be set in variable $SERVICE_URL)
# --push-auth-service-account: Service account for authentication
# Exam Tip: Push subscription sends HTTP POST to endpoint
# Pull subscription: Application polls for messages
# Use Case: Event-driven architecture - Storage → Pub/Sub → Cloud Run
gcloud pubsub subscriptions create pdf-conv-sub \
  --topic new-doc \
  --push-endpoint=$SERVICE_URL \
  --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com

# ==============================================================================
# UPLOAD TEST FILES
# ==============================================================================

# gsutil -m cp -r gs://<SOURCE> gs://<DESTINATION>
# Copy test files to upload bucket to trigger PDF conversion
# -m: Multi-threaded/parallel copy (faster)
# -r: Recursive (copy directory contents)
# Effect: Files uploaded → triggers notification → Pub/Sub → Cloud Run
gsutil -m cp -r gs://spls/gsp762/* gs://$GOOGLE_CLOUD_PROJECT-upload

################################################################################
# LAB COMPLETE - KEY CONCEPTS REVIEW
################################################################################
#
# 1. Event-Driven Architecture Pattern:
#    Upload to GCS → Storage Notification → Pub/Sub Topic → 
#    Push Subscription → Cloud Run Service → Process file → Save to GCS
#
# 2. Cloud Storage Notifications:
#    - gsutil notification create: Set up event triggers
#    - Events: OBJECT_FINALIZE, OBJECT_DELETE, OBJECT_METADATA_UPDATE
#    - Publishes to Pub/Sub when events occur
#    - Alternative: Eventarc (newer, more features)
#
# 3. Pub/Sub Push Subscriptions:
#    - Sends HTTP POST to endpoint
#    - Requires authentication for Cloud Run
#    - Service account must have run.invoker role
#    - Automatic retry on failure
#
# 4. Cloud Run for Background Processing:
#    - No allow-unauthenticated (secure)
#    - Higher memory for processing (2Gi)
#    - Max instances to control costs
#    - Environment variables for configuration
#
# 5. IAM Roles Required:
#    - run.invoker: Call Cloud Run service
#    - iam.serviceAccountTokenCreator: Create auth tokens
#    - Assigned to pubsub-cloud-run-invoker service account
#
# 6. Best Practices:
#    - Use service accounts (not user accounts) for automation
#    - Set max-instances to prevent runaway costs
#    - Use push subscriptions for real-time processing
#    - Store results in separate bucket (processed vs upload)
#    - Use environment variables for bucket names
#
# 7. Alternative Approaches:
#    - Eventarc: Newer, simpler event routing
#    - Cloud Functions: For simpler processing
#    - Cloud Tasks: For scheduled or delayed processing
#
################################################################################