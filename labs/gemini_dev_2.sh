export PROJECT_ID=$(gcloud config list project --format="value(core.project)")
export USER=$(gcloud config list account --format "value(core.account)")
export REGION=us-east4
echo "PROJECT_ID=${PROJECT_ID}"
echo "USER=${USER}"
echo "REGION=${REGION}"

gcloud services enable cloudaicompanion.googleapis.com --project ${PROJECT_ID}
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member user:${USER} --role=roles/cloudaicompanion.user
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member user:${USER} --role=roles/serviceusage.serviceUsageViewer


export CLUSTER_NAME=my-cluster
export CONFIG_NAME=my-config
export WS_NAME=my-workstation
export REGION=us-east4
gcloud workstations configs create ${CONFIG_NAME} --cluster=${CLUSTER_NAME} --region=${REGION} --machine-type="e2-standard-4" --pd-disk-size=200 --pd-disk-type="pd-standard" --pool-size=1
gcloud workstations create ${WS_NAME} --cluster=${CLUSTER_NAME} --config=${CONFIG_NAME} --region=${REGION}

sudo apt update
sudo apt -y upgrade
sudo apt install -y python3-venv
python3 -m venv ~/env
source ~/env/bin/activate

which python3