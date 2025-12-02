cat > cloudbuild.yaml <<EOF
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: [ 'build', '-t', '${REPO}/sample-node-app-image', '.' ]
images:
- '${REPO}/sample-node-app-image'
EOF

gcloud builds submit --region=$REGION --config=cloudbuild.yaml

gcloud run deploy sample-node-app --image ${REPO}/sample-node-app-image --region $REGION --allow-unauthenticated

gcloud run services list

https://sample-node-app-981259290698.us-west1.run.app/service/products | jq