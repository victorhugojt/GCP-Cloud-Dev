gcloud compute ssh lab-vm --zone=us-west1-b

sudo chmod 666 /var/run/docker.sock

docker stop [CONTAINER ID]

gcloud auth configure-docker ${REGION}-docker.pkg.dev

docker stop $(docker ps -q)

docker rm $(docker ps -aq)

docker rmi ${REGION}-docker.pkg.dev/$PROJECT_ID/my-repo/my-app:0.2

docker rmi -f $(docker images -aq)