gcloud firestore databases create --location=europe-west1

gcloud storage buckets create gs://${GOOGLE_CLOUD_PROJECT}-covers --location=europe-west1 --no-public-access-prevention --uniform-bucket-level-access

gcloud storage buckets add-iam-policy-binding gs://${GOOGLE_CLOUD_PROJECT}-covers --member=allUsers --role=roles/storage.legacyObjectReader

gcloud services enable secretmanager.googleapis.com

mv ~/client_secret*.json ~/client_secret.json

gcloud secrets create bookshelf-client-secrets --data-file=$HOME/client_secret.json

tr -dc A-Za-z0-9 </dev/urandom | head -c 20 | gcloud secrets create flask-secret-key --data-file=-

cd ~/bookshelf; EXTERNAL_HOST_URL="https://8080-${WEB_HOST}" ~/.local/bin/gunicorn -b :8080 main:app

gcloud artifacts repositories create app-repo \
  --repository-format=docker \
  --location=europe-west1

  gcloud artifacts repositories describe app-repo \
  --location=europe-west1

  gcloud builds submit \
  --pack image=europe-west1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/app-repo/bookshelf \
  ~/bookshelf

  gcloud builds list

  gcloud run deploy bookshelf \
  --image=europe-west1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/app-repo/bookshelf \
  --region=europe-west1 --allow-unauthenticated \
  --update-env-vars=GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT}

  echo "https://bookshelf-$(gcloud projects describe $GOOGLE_CLOUD_PROJECT --format="value(projectNumber)").europe-west1.run.app"

  gcloud iam service-accounts create bookshelf-run-sa

  gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:bookshelf-run-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:bookshelf-run-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/cloudtranslate.user"
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:bookshelf-run-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/datastore.user"
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:bookshelf-run-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/storage.objectUser"


gcloud run deploy bookshelf \
  --image=europe-west1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/app-repo/bookshelf \
  --region=europe-west1 --allow-unauthenticated \
  --update-env-vars=GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT} \
  --service-account=bookshelf-run-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com

  echo "https://bookshelf-$(gcloud projects describe $GOOGLE_CLOUD_PROJECT --format="value(projectNumber)").europe-west1.run.app"


  echo "bookshelf-$(gcloud projects describe $GOOGLE_CLOUD_PROJECT --format="value(projectNumber)").europe-west1.run.app"

  echo "https://bookshelf-$(gcloud projects describe $GOOGLE_CLOUD_PROJECT --format="value(projectNumber)").europe-west1.run.app/oauth2callback"

  gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:bookshelf-run-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/errorreporting.writer"