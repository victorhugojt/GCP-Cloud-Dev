PROJECT_ID=$(gcloud config get-value project)
IMAGE_NAME=valkyrie-app
TAG=v0.0.3
REGION=us-west1
REPO=valkyrie-repo

echo "REGION=${REGION}"
echo "REPO=${REPO}"
echo "PROJECT_ID=${PROJECT_ID}"
echo "IMAGE_NAME=${IMAGE_NAME}"
echo "TAG=${TAG}"

docker build -t $IMAGE_NAME:$TAG .

docker run -p 8080:8080 $IMAGE_NAME:$TAG

docker images | grep valkyrie-pro

gcloud artifacts repositories create $REPO \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository for $IMAGE_NAME"

gcloud auth configure-docker $REGION-docker.pkg.dev

docker tag $IMAGE_NAME:$TAG $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE_NAME:$TAG

docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE_NAME:$TAG

REGION_K8=us-west1-b

gcloud container clusters get-credentials $REGION_K8

kubectl apply -f deployment.yaml

kubectl apply -f service.yaml

kubectl get services

kubectl get pods

kubectl get deployments

kubectl get nodes

kubectl get all