gcloud config set compute/region us-east4

gcloud config set compute/zone us-east4-b

gcloud container clusters create --machine-type=e2-medium --zone=us-east4-b lab-cluster

gcloud container clusters get-credentials lab-cluster

kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0

kubectl expose deployment hello-server --type=LoadBalancer --port 8080

kubectl get service

gcloud container clusters delete lab-cluster

http://[EXTERNAL-IP]:8080
http://34.118.229.232:8080

--

gcloud container clusters create io --zone europe-west1-d

kubectl create deployment nginx --image=nginx:1.27.0

kubectl create deployment nginx --image=nginx:1.27.0

kubectl expose deployment nginx --port 80 --type LoadBalancer

kubectl get services


curl http://35.187.87.83:80


kubectl create -f pods/fortune-app.yaml

kubectl get pods

kubectl port-forward fortune-app 10080:8080

curl http://127.0.0.1:10080

34.77.88.16

curl -k https://34.38.223.118:31000

curl -k https://34.140.129.222