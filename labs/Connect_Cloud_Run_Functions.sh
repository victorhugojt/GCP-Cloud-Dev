# VPC Access Connector

 PROJECT_ID=$(gcloud config get-value project)
 REGION=set at lab start

 gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com \
  redis.googleapis.com \
  vpcaccess.googleapis.com


  REDIS_INSTANCE=customerdb

  gcloud redis instances create $REDIS_INSTANCE \
 --size=2 --region=$REGION \
 --redis-version=redis_6_x

 gcloud redis instances describe $REDIS_INSTANCE --region=$REGION

 REDIS_IP=$(gcloud redis instances describe $REDIS_INSTANCE --region=$REGION --format="value(host)"); echo $REDIS_IP
10.3.89.115

REDIS_PORT=$(gcloud redis instances describe $REDIS_INSTANCE --region=$REGION --format="value(port)"); echo $REDIS_PORT
6379


 gcloud compute networks vpc-access connectors \
  describe test-connector \
  --region $REGION

  TOPIC=add_redis

  gcloud pubsub topics create $TOPIC

  TODO

  gcloud storage cp gs://cloud-training/CBL492/startup.sh .

  gcloud compute instances create webserver-vm \
--image-project=debian-cloud \
--image-family=debian-11 \
--metadata-from-file=startup-script=./startup.sh \
--machine-type e2-standard-2 \
--tags=http-server \
--scopes=https://www.googleapis.com/auth/cloud-platform \
--zone $ZONE

  gcloud compute --project=$PROJECT_ID \
 firewall-rules create default-allow-http \
 --direction=INGRESS \
 --priority=1000 \
 --network=default \
 --action=ALLOW \
 --rules=tcp:80 \
 --source-ranges=0.0.0.0/0 \
 --target-tags=http-server

 VM_INT_IP=$(gcloud compute instances describe webserver-vm --format='get(networkInterfaces[0].networkIP)' --zone $ZONE); echo $VM_INT_IP

 VM_EXT_IP=$(gcloud compute instances describe webserver-vm --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone $ZONE); echo $VM_EXT_IP