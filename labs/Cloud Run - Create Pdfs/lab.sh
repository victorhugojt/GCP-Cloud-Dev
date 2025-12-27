# activate your lab account
gcloud auth list --filter=status:ACTIVE --format="value(account)"

gcloud services enable cloudaicompanion.googleapis.com

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter

  gcloud run deploy pdf-converter \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter \
  --platform managed \
  --region us-east4 \
  --memory=2Gi \
  --no-allow-unauthenticated \
  --set-env-vars PDF_BUCKET=$GOOGLE_CLOUD_PROJECT-processed \
  --max-instances=3


  gsutil notification create -t new-doc -f json -e OBJECT_FINALIZE gs://$GOOGLE_CLOUD_PROJECT-upload

  gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"

  gcloud run services add-iam-policy-binding pdf-converter \
  --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
  --role=roles/run.invoker \
  --region us-east4 \
  --platform managed

  PROJECT_NUMBER=$(gcloud projects list \
 --format="value(PROJECT_NUMBER)" \
 --filter="$GOOGLE_CLOUD_PROJECT")


 gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member=serviceAccount:qwiklabs-gcp-01-d97271f75737@qwiklabs-gcp-01-d97271f75737.iam.gserviceaccount.com \
  --role=roles/iam.serviceAccountTokenCreator

  gcloud pubsub subscriptions create pdf-conv-sub \
  --topic new-doc \
  --push-endpoint=$SERVICE_URL \
  --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com

  gsutil -m cp -r gs://spls/gsp762/* gs://$GOOGLE_CLOUD_PROJECT-upload