gcloud config set project \
$(gcloud projects list --format='value(PROJECT_ID)' \
--filter='qwiklabs-gcp')

REGION=us-east4

gcloud config set run/region $REGION

gcloud config set run/platform managed

git clone https://github.com/rosera/pet-theory.git && cd pet-theory/lab07

Public_Service_Image_Name=billing-staging-api:0.1
Public_Service_Name=Public billing service

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$Public_Service_Image_Name

  gcloud run deploy $Public_Service_Name \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$Public_Service_Image_Name \
  --platform managed \
  --region us-east4 \
  --allow-unauthenticated \
  --max-instances=2


frontend_service_image_name=frontend-staging:0.1
frontend_service_name=Frontend staging service

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$frontend_service_image_name

  gcloud run deploy $frontend_service_name \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$frontend_service_image_name \
  --platform managed \
  --region us-east4 \
  --allow-unauthenticated \
  --max-instances=2


private_service_image_name=billing-staging-api:0.2
private_service_name=Private billing service

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$private_service_image_name

  gcloud run deploy $private_service_name \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$private_service_image_name \
  --platform managed \
  --region us-east4 \
  --no-allow-unauthenticated \
  --max-instances=2


 gcloud iam service-accounts create billing-service \
    --display-name="Billing Service Cloud Run"


gcloud run deploy billing-production-service \
    --image=gcr.io/$PROJECT_ID/billing-prod-api:0.1 \
    --service-account=billing-service@$PROJECT_ID.iam.gserviceaccount.com \
    --region=$REGION \
    --no-allow-unauthenticated

gcloud run services update billing-production-service \
    --service-account=billing-service@$PROJECT_ID.iam.gserviceaccount.com \
    --region=$REGION


PROD_BILLING_URL=$(gcloud run services describe Private billing service \
--platform managed \
--region REGION \
--format "value(status.url)")

curl -X get -H "Authorization: Bearer \
$(gcloud auth print-identity-token)" \
$PROD_BILLING_URL

# Create the Frontend service account
gcloud iam service-accounts create frontend-prod-service \
    --display-name="Billing Service Cloud Run Invoker"

# Grant the run.invoker role to invoke the billing service
gcloud run services add-iam-policy-binding billing-production-service \
    --member="serviceAccount:frontend-prod-service@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/run.invoker" \
    --region=$REGION


gcloud run deploy frontend-prod-service \
    --image=gcr.io/$PROJECT_ID/frontend-prod-service:0.1 \
    --service-account=frontend-prod-service@$PROJECT_ID.iam.gserviceaccount.com \
    --region=$REGION


# Deploy with the service account
gcloud run deploy frontend-prod-service \
    --image=gcr.io/$PROJECT_ID/frontend-prod-api:0.1 \
    --service-account=frontend-prod-service@$PROJECT_ID.iam.gserviceaccount.com \
    --region=$REGION \
    --allow-unauthenticated