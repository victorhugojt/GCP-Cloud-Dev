 BILLING_SERVICE_URL=$(gcloud run services list \
  --format='value(URL)' \
  --filter="billing-service")

 gcloud run deploy billing-service \
  --image gcr.io/qwiklabs-resources/gsp723-parking-service \
  --region $LOCATION \
  --no-allow-unauthenticated


BILLING_INITIATOR_EMAIL=$(gcloud iam service-accounts list --filter="Billing Initiator" --format="value(EMAIL)"); echo $BILLING_INITIATOR_EMAIL


gcloud iam service-accounts keys create key.json --iam-account=${BILLING_INITIATOR_EMAIL}

gcloud auth activate-service-account --key-file=key.json

gcloud projects remove-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member=serviceAccount:${BILLING_INITIATOR_EMAIL} \
  --role=roles/run.invoker

  gcloud run services add-iam-policy-binding billing-service --region $LOCATION \
  --member=serviceAccount:${BILLING_INITIATOR_EMAIL} \
  --role=roles/run.invoker --platform managed