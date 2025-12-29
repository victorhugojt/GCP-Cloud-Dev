gcloud config set project \
$(gcloud projects list --format='value(PROJECT_ID)' \
--filter='qwiklabs-gcp')

REGION=us-east4

gcloud config set run/region $REGION

gcloud config set run/platform managed

git clone https://github.com/rosera/pet-theory.git && cd pet-theory/lab07

Public_Service_Image_Name=billing-staging-api:0.1
Public_Service_Name=public-billing-service-385

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$Public_Service_Image_Name

gcloud run deploy $Public_Service_Name \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$Public_Service_Image_Name \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --max-instances=2

  --https://public-billing-service-385-146184502724.us-east4.run.app


frontend_service_image_name=frontend-staging:0.1
frontend_service_name=frontend-staging-service-365

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$frontend_service_image_name

gcloud run deploy $frontend_service_name \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$frontend_service_image_name \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --max-instances=2


private_service_image_name=billing-staging-api:0.2
private_service_name=private-billing-service-523

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$private_service_image_name

gcloud run deploy $private_service_name \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$private_service_image_name \
  --platform managed \
  --region $REGION \
  --no-allow-unauthenticated \
  --max-instances=2


BILLING_URL=$(gcloud run services describe $private_service_name \
--platform managed \
--region $REGION \
--format "value(status.url)")


--------------------------------------------------

billing_sa_name=billing-service-sa-645

gcloud iam service-accounts create $billing_sa_name \
    --display-name="Billing Service Cloud Run"

prod_billing_image_name=billing-prod-api:0.1
prod_billing_service_name=billing-prod-service-356

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$prod_billing_image_name

gcloud run deploy $prod_billing_service_name \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$prod_billing_image_name \
  --service-account=$billing_sa_name \
  --platform managed \
  --region $REGION \
  --no-allow-unauthenticated \
  --max-instances=2

PROD_BILLING_URL=$(gcloud run services describe $prod_billing_service_name \
--platform managed \
--region REGION \
--format "value(status.url)")

curl -X get -H "Authorization: Bearer \
$(gcloud auth print-identity-token)" \
$PROD_BILLING_URL

fronend_sa_name=frontend-service-sa-583
frontend_service_name=frontend-staging-service-365
frontend_prod_service_name=frontend-prod-service-365

# Create the Frontend service account
gcloud iam service-accounts create $fronend_sa_name \
            --display-name="Billing Service Cloud Run Invoker"


gcloud run services add-iam-policy-binding $frontend_service_name \
    --member="serviceAccount:${fronend_sa_name}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/run.invoker" \
    --region=$REGION


frontend_prod_service_image_name=frontend-prod:0.1
frontend_prod_service_name=frontend-prod-service-516

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/$frontend_prod_service_image_name

gcloud run deploy $frontend_prod_service_name \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/$frontend_prod_service_image_name \
  --service-account=$fronend_sa_name \
  --region $REGION \
  --allow-unauthenticated