PROJECT_ID=$(gcloud config get-value project)
REGION=us-east4

gcloud services enable artifactregistry.googleapis.com run.googleapis.com translate.googleapis.com


gcloud storage cp gs://cloud-training/CBL513/sample-apps/sample-py-app.zip . && unzip sample-py-app

# Build and deploy directly with Cloud Run
gcloud run deploy sample-py-app \
  --source . \
  --region=$REGION \
  --allow-unauthenticated