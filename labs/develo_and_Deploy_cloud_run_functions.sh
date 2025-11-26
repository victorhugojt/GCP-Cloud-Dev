PROJECT_ID=$(gcloud config get-value project)
REGION=set at lab start

gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  storage.googleapis.com \
  pubsub.googleapis.com


FUNCTION_URI=$(gcloud run services describe temperature-converter --region $REGION --format 'value(status.url)'); echo $FUNCTION_URI

https://temperature-converter-ej3hksokja-uc.a.run.app

SERVICE_ACCOUNT=$(gcloud storage service-agent)

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$SERVICE_ACCOUNT --role roles/pubsub.publisher

gcloud storage cp gs://cloud-training/CBL491/data/average-temps.csv .

BUCKET="gs://gcf-temperature-data-$PROJECT_ID"

gcloud storage buckets create -l $REGION $BUCKET


gcloud functions deploy temperature-data-checker \
 --gen2 \
 --runtime nodejs20 \
 --entry-point checkTempData \
 --source . \
 --region $REGION \
 --trigger-bucket $BUCKET \
 --trigger-location $REGION \
 --max-instances 1

 gcloud storage cp ~/average-temps.csv $BUCKET/average-temps.csv

 gcloud functions logs read temperature-data-checker \
 --region $REGION --gen2 --limit=100 --format "value(log)"

unzip ../services_temperature-converter_1762344813.432000.zip