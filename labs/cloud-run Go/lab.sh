gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')

go build -o server

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1

  gcloud run deploy rest-api \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1 \
  --platform managed \
  --region us-east4 \
  --allow-unauthenticated \
  --max-instances=2


  gsutil mb -c standard -l us-east4 gs://$GOOGLE_CLOUD_PROJECT-customer


  gsutil cp -r gs://spls/gsp645/2019-10-06T20:10:37_43617 gs://$GOOGLE_CLOUD_PROJECT-customer

  gcloud beta firestore import gs://$GOOGLE_CLOUD_PROJECT-customer/2019-10-06T20:10:37_43617/

  gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2