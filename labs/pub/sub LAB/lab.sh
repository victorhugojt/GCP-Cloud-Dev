gcloud config set compute/zone "us-east1-b"
export ZONE=$(gcloud config get compute/zone)

gcloud config set compute/region "us-east1"
export REGION=$(gcloud config get compute/region)

gcloud pubsub topics create new-lab-report

gcloud services enable run.googleapis.com

export LAB_REPORT_SERVICE_URL=$(gcloud run services describe lab-report-service --platform managed --region us-east1 --format="value(status.address.url)")

gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"

gcloud run services add-iam-policy-binding email-service --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --region us-east1 --platform managed

PROJECT_NUMBER=$(gcloud projects list --filter="qwiklabs-gcp" --format='value(PROJECT_NUMBER)')

gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator

EMAIL_SERVICE_URL=$(gcloud run services describe email-service --platform managed --region us-east1 --format="value(status.address.url)")

gcloud run services add-iam-policy-binding sms-service --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --region us-east1 --platform managed

SMS_SERVICE_URL=$(gcloud run services describe sms-service --platform managed --region us-east1 --format="value(status.address.url)")

gcloud pubsub subscriptions create sms-service-sub --topic new-lab-report --push-endpoint=$SMS_SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com