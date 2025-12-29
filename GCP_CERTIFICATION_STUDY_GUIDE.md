# GCP Cloud Developer Certification Study Guide

## Overview
This guide consolidates key concepts from all lab exercises to help prepare for the Google Cloud Professional Cloud Developer certification exam.

---

## Table of Contents
1. [Cloud Run](#cloud-run)
2. [Docker and Containers](#docker-and-containers)
3. [IAM and Service Accounts](#iam-and-service-accounts)
4. [Cloud Build](#cloud-build)
5. [Firestore and Databases](#firestore-and-databases)
6. [Cloud Storage](#cloud-storage)
7. [Secret Manager](#secret-manager)
8. [Artifact Registry](#artifact-registry)
9. [Pub/Sub and Event-Driven Architecture](#pubsub-and-event-driven-architecture)
10. [Kubernetes (GKE)](#kubernetes-gke)
11. [AI/ML Integration (Gemini)](#aiml-integration)
12. [Common Commands Quick Reference](#common-commands-quick-reference)

---

## Cloud Run

### Core Concepts
- **Serverless container platform**: Pay only for actual usage (per 100ms)
- **Auto-scaling**: From 0 to max instances based on traffic
- **Fully managed**: Google handles infrastructure, scaling, and security

### Authentication Options
```bash
# Public access
--allow-unauthenticated

# Requires authentication (identity token)
--no-allow-unauthenticated
```

### Key Flags
- `--image`: Container image URL
- `--region`: Geographic deployment location
- `--platform managed`: Serverless (vs gke for GKE)
- `--service-account`: Identity the service runs as
- `--max-instances`: Limit concurrent instances (cost control)
- `--memory`: 128Mi to 8Gi (default: 512Mi)
- `--update-env-vars`: Set environment variables
- `--update-secrets`: Mount secrets from Secret Manager

### Service-to-Service Authentication Pattern
```bash
# 1. Create service account
gcloud iam service-accounts create frontend-sa

# 2. Grant run.invoker on backend service
gcloud run services add-iam-policy-binding backend-service \
  --member="serviceAccount:frontend-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.invoker" \
  --region=REGION

# 3. Deploy frontend with service account
gcloud run deploy frontend \
  --service-account=frontend-sa \
  --image=IMAGE_URL
```

### Testing Authenticated Services
```bash
# Generate identity token
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" SERVICE_URL
```

### Exam Tips
- Default compute SA has editor role (too permissive) - always use custom SA
- Services are versioned as revisions (immutable)
- Can split traffic between revisions
- Identity tokens valid for 1 hour (different from OAuth access tokens)
- Cold starts: Lightweight containers start faster

---

## Docker and Containers

### Dockerfile Basics
```dockerfile
FROM node:18-alpine          # Base image (use specific versions)
WORKDIR /app                 # Working directory
COPY . .                     # Copy files
RUN npm install              # Install dependencies (build time)
EXPOSE 8080                  # Document port (informational)
CMD ["node", "server.js"]    # Default command (runtime)
```

### Key Differences
- **COPY vs ADD**: Use COPY (ADD can extract archives/download URLs)
- **CMD vs ENTRYPOINT**: CMD easily overridden, ENTRYPOINT is fixed command
- **RUN vs CMD**: RUN at build time, CMD at container start

### Container Lifecycle
```bash
# Build image
docker build -t IMAGE_NAME:TAG .

# Run container
docker run -p 8080:80 --name my-app IMAGE_NAME:TAG

# List running containers
docker ps

# View logs
docker logs CONTAINER_ID
docker logs -f CONTAINER_ID  # Follow mode

# Execute command in container
docker exec -it CONTAINER_ID bash

# Stop and remove
docker stop CONTAINER_ID
docker rm CONTAINER_ID

# Remove image
docker rmi IMAGE_NAME:TAG
```

### Cleanup Commands
```bash
# Stop all running containers
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all images
docker rmi -f $(docker images -aq)
```

### Exam Tips
- Each Dockerfile instruction creates a layer
- Layers are cached (order matters for build speed)
- Combine RUN commands to minimize layers
- Use .dockerignore to exclude files
- Multi-stage builds reduce final image size

---

## IAM and Service Accounts

### Service Account Email Format
```
SERVICE_ACCOUNT_NAME@PROJECT_ID.iam.gserviceaccount.com
```

### Common IAM Roles

#### Cloud Run
- `roles/run.invoker`: Can call Cloud Run service
- `roles/run.developer`: Can deploy services
- `roles/run.admin`: Full control

#### Storage
- `roles/storage.objectViewer`: Read objects + list bucket
- `roles/storage.objectCreator`: Upload objects
- `roles/storage.objectUser`: Read + Write (Viewer + Creator)
- `roles/storage.admin`: Full control

#### Firestore/Datastore
- `roles/datastore.user`: Read/write data
- `roles/datastore.viewer`: Read-only
- `roles/datastore.owner`: Full control

#### Secrets
- `roles/secretmanager.secretAccessor`: Read secret values
- `roles/secretmanager.secretVersionManager`: Create versions

#### Translation
- `roles/cloudtranslate.user`: Use Translation API

#### Error Reporting
- `roles/errorreporting.writer`: Write error reports

### IAM Best Practices
1. **Principle of Least Privilege**: Grant minimum necessary permissions
2. **Resource-level > Project-level**: More specific is better
3. **Service Accounts > User Accounts**: For automation
4. **One SA per service**: Easier to audit and control
5. **Rotate keys regularly**: If using key files (prefer Workload Identity)

### Policy Binding Commands
```bash
# Project-level (broad)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="ROLE"

# Resource-level (specific - preferred)
gcloud run services add-iam-policy-binding SERVICE_NAME \
  --member="serviceAccount:SA_EMAIL" \
  --role="ROLE" \
  --region=REGION
```

### Service Account Keys (Use Sparingly)
```bash
# Create key file
gcloud iam service-accounts keys create key.json \
  --iam-account=SA_EMAIL

# Authenticate using key
gcloud auth activate-service-account --key-file=key.json
```

**Security Warning**: Keys don't expire by default. Never commit to git. Use Workload Identity or metadata server when possible.

---

## Cloud Build

### cloudbuild.yaml Structure
```yaml
steps:
  # Step 1: Build image
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', '${REPO}/image:tag', '.']
    
  # Step 2: Run tests (optional)
  - name: 'gcr.io/cloud-builders/docker'
    args: ['run', '${REPO}/image:tag', 'npm', 'test']

# Images to push after successful build
images:
  - '${REPO}/image:tag'
```

### Common Cloud Builders
- `gcr.io/cloud-builders/docker`: Docker commands
- `gcr.io/cloud-builders/gcloud`: gcloud CLI
- `gcr.io/cloud-builders/npm`: Node.js/npm
- `gcr.io/cloud-builders/mvn`: Maven (Java)
- `gcr.io/cloud-builders/gradle`: Gradle (Java)
- `gcr.io/cloud-builders/git`: Git operations
- `gcr.io/cloud-builders/gsutil`: Cloud Storage operations

### Substitution Variables
```yaml
# Built-in variables
$PROJECT_ID, $BUILD_ID, $COMMIT_SHA, $BRANCH_NAME, $TAG_NAME

# Custom variables (pass via --substitutions)
${REPO}, ${ENV}, ${VERSION}
```

### Commands
```bash
# Submit build
gcloud builds submit --config=cloudbuild.yaml

# With substitutions
gcloud builds submit --substitutions=_ENV=prod,_VERSION=1.0

# View build history
gcloud builds list

# Stream logs
gcloud builds log BUILD_ID --stream
```

### Buildpacks (No Dockerfile)
```bash
# Deploy directly from source
gcloud run deploy SERVICE_NAME --source .

# Or build image only
gcloud builds submit --pack image=IMAGE_URL
```

**Supported languages**: Python, Node.js, Go, Java, .NET

### Exam Tips
- Each step runs in isolated container
- Steps run sequentially by default (use `waitFor` for parallelism)
- First 120 build-minutes/day are free
- Default timeout: 10 minutes (configurable)
- Use Cloud Source Repositories or GitHub for automated triggers

---

## Firestore and Databases

### Firestore Modes (Choose at creation - permanent)
1. **Native Mode**: Document database, real-time, offline support
2. **Datastore Mode**: Compatible with legacy Datastore, no real-time

### Structure
```
Collection → Document → Subcollection → Document
```

### Commands
```bash
# Create database
gcloud firestore databases create --location=REGION

# Export (backup)
gcloud firestore export gs://BUCKET

# Import (restore)
gcloud firestore import gs://BUCKET/EXPORT_DIR
```

### Exam Tips
- Location is permanent (affects latency and compliance)
- `roles/datastore.user` works for both Firestore and Datastore
- Exports are timestamped for point-in-time recovery
- Real-time listeners available in Native mode
- Strong consistency within entity group

---

## Cloud Storage

### Storage Classes
| Class | Use Case | Minimum Storage | Access Pattern |
|-------|----------|-----------------|----------------|
| **Standard** | Frequent access | None | Hot data |
| **Nearline** | < once/month | 30 days | Backups |
| **Coldline** | < once/quarter | 90 days | Disaster recovery |
| **Archive** | < once/year | 365 days | Long-term archival |

### Commands
```bash
# Create bucket
gsutil mb -c STORAGE_CLASS -l LOCATION gs://BUCKET_NAME

# Upload files
gsutil cp FILE gs://BUCKET/
gsutil cp -r DIRECTORY gs://BUCKET/

# Download files
gsutil cp gs://BUCKET/FILE .
gsutil cp -r gs://BUCKET/DIRECTORY .

# List files
gsutil ls gs://BUCKET/

# Make public
gsutil iam ch allUsers:objectViewer gs://BUCKET

# IAM binding
gcloud storage buckets add-iam-policy-binding gs://BUCKET \
  --member=allUsers \
  --role=roles/storage.objectViewer
```

### Storage Notifications
```bash
# Create notification (sends to Pub/Sub)
gsutil notification create -t TOPIC -f json -e OBJECT_FINALIZE gs://BUCKET
```

**Events**: OBJECT_FINALIZE, OBJECT_DELETE, OBJECT_ARCHIVE, OBJECT_METADATA_UPDATE

### Exam Tips
- Bucket names globally unique
- Location matches compute resources for low latency
- Signed URLs for temporary access (no authentication)
- Object versioning for accidental deletion protection
- Lifecycle policies for automatic class transitions

---

## Secret Manager

### Commands
```bash
# Enable API
gcloud services enable secretmanager.googleapis.com

# Create secret from file
gcloud secrets create SECRET_NAME --data-file=FILE

# Create secret from stdin
echo "password123" | gcloud secrets create SECRET_NAME --data-file=-

# Add new version
echo "new_password" | gcloud secrets versions add SECRET_NAME --data-file=-

# Access secret
gcloud secrets versions access latest --secret=SECRET_NAME
```

### Use in Cloud Run
```bash
# Mount secret as environment variable
gcloud run deploy SERVICE \
  --update-secrets=ENV_VAR=SECRET_NAME:latest

# Mount secret as file
gcloud run deploy SERVICE \
  --update-secrets=/path/to/file=SECRET_NAME:latest
```

### Best Practices
- Never hardcode secrets in source code
- Never commit secrets to version control
- Use Secret Manager (not environment variables)
- Grant `secretAccessor` role to service accounts
- Use secret versions for rotation

### Exam Tips
- Secrets are versioned (can have multiple versions)
- Billed per secret version per month + access operations
- Automatic encryption at rest
- Audit logs track secret access
- Can reference specific version or "latest"

---

## Artifact Registry

### Create Repository
```bash
# Docker repository
gcloud artifacts repositories create REPO_NAME \
  --repository-format=docker \
  --location=REGION \
  --description="Description"
```

**Supported formats**: docker, maven, npm, python, apt, yum

### Authentication
```bash
# Configure Docker
gcloud auth configure-docker REGION-docker.pkg.dev
```

### Image URL Format
```
REGION-docker.pkg.dev/PROJECT_ID/REPO_NAME/IMAGE_NAME:TAG
```

### Commands
```bash
# List repositories
gcloud artifacts repositories list

# List images
gcloud artifacts docker images list REGION-docker.pkg.dev/PROJECT/REPO

# Delete image
gcloud artifacts docker images delete IMAGE_URL
```

### Artifact Registry vs Container Registry
| Feature | Artifact Registry | Container Registry (gcr.io) |
|---------|------------------|---------------------------|
| Status | Current | Legacy |
| Formats | Multiple | Docker only |
| Location | Regional | Multi-regional |
| Features | More | Basic |
| Recommendation | ✅ Use this | Migrating to AR |

### Exam Tips
- Regional storage (lower latency)
- IAM-based access control
- Vulnerability scanning available
- Supports Docker BuildKit cache
- Can set up cleanup policies

---

## Pub/Sub and Event-Driven Architecture

### Core Concepts
- **Topic**: Named resource for messages
- **Subscription**: Named resource for receiving messages
- **Publisher**: Sends messages to topic
- **Subscriber**: Receives messages from subscription

### Subscription Types
1. **Pull**: Application polls for messages
2. **Push**: Pub/Sub sends HTTP POST to endpoint

### Commands
```bash
# Create topic
gcloud pubsub topics create TOPIC_NAME

# Create pull subscription
gcloud pubsub subscriptions create SUB_NAME --topic=TOPIC_NAME

# Create push subscription
gcloud pubsub subscriptions create SUB_NAME \
  --topic=TOPIC_NAME \
  --push-endpoint=HTTPS_URL \
  --push-auth-service-account=SA_EMAIL

# Publish message
gcloud pubsub topics publish TOPIC_NAME --message="Hello"

# Pull messages
gcloud pubsub subscriptions pull SUB_NAME --auto-ack
```

### Event-Driven Pattern
```
Cloud Storage Upload → Storage Notification → Pub/Sub Topic → 
Push Subscription → Cloud Run Service
```

### Dead Letter Topics
```bash
# Create DLQ topic
gcloud pubsub topics create TOPIC-dead-letter

# Create subscription with DLQ
gcloud pubsub subscriptions create SUB_NAME \
  --topic=TOPIC_NAME \
  --dead-letter-topic=TOPIC-dead-letter \
  --max-delivery-attempts=5
```

### Exam Tips
- Messages retained for up to 7 days
- At-least-once delivery (may have duplicates)
- Messages unordered by default
- Push subscriptions require HTTPS endpoint
- Automatic retry with exponential backoff
- Use message attributes for filtering

---

## Kubernetes (GKE)

### Cluster Management
```bash
# Create cluster
gcloud container clusters create CLUSTER_NAME \
  --machine-type=e2-medium \
  --zone=ZONE

# Get credentials
gcloud container clusters get-credentials CLUSTER_NAME

# Delete cluster
gcloud container clusters delete CLUSTER_NAME
```

### Workload Types
- **Pod**: Smallest unit (1+ containers)
- **Deployment**: Manages ReplicaSets and Pods
- **ReplicaSet**: Ensures desired replicas running
- **StatefulSet**: For stateful applications
- **DaemonSet**: One pod per node
- **Job/CronJob**: Batch processing

### Service Types
- **ClusterIP**: Internal only (default)
- **NodePort**: Exposes on node IP:port
- **LoadBalancer**: Creates cloud load balancer
- **ExternalName**: DNS CNAME

### Common Commands
```bash
# Create deployment
kubectl create deployment NAME --image=IMAGE

# Expose deployment
kubectl expose deployment NAME --type=LoadBalancer --port=80

# Get resources
kubectl get pods
kubectl get services
kubectl get deployments

# Describe resource
kubectl describe pod POD_NAME

# View logs
kubectl logs POD_NAME
kubectl logs -f POD_NAME  # Follow

# Execute command
kubectl exec -it POD_NAME -- bash

# Port forward
kubectl port-forward POD_NAME 8080:80
```

### Declarative Configuration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
    image: nginx:1.27
    ports:
    - containerPort: 80
```

```bash
# Apply configuration
kubectl apply -f config.yaml

# Delete resources
kubectl delete -f config.yaml
```

### GKE vs Cloud Run

| Feature | GKE | Cloud Run |
|---------|-----|-----------|
| **Complexity** | High | Low |
| **Control** | Full K8s | Limited |
| **Use Case** | Complex microservices | Web apps, APIs |
| **State** | Stateful + Stateless | Stateless only |
| **Scaling** | Manual + HPA | Automatic |
| **Cost** | Per node | Per request |

### Exam Tips
- GKE = Managed Kubernetes (Google handles control plane)
- Autopilot mode: Google manages nodes too
- Use GKE for: Complex apps, batch jobs, ML workloads
- Use Cloud Run for: Simpler apps, event-driven, auto-scaling

---

## AI/ML Integration

### Vertex AI (Gemini)
```bash
# Enable API
gcloud services enable aiplatform.googleapis.com

# Environment variables needed
PROJECT_ID=your-project
REGION=us-central1

# Pass to Cloud Run
gcloud run deploy SERVICE \
  --set-env-vars=PROJECT_ID=$PROJECT_ID,REGION=$REGION
```

### Python SDK Example
```python
import vertexai
from vertexai.generative_models import GenerativeModel

vertexai.init(project=PROJECT_ID, location=REGION)
model = GenerativeModel("gemini-pro")
response = model.generate_content("Hello!")
```

### Exam Tips
- Requires `aiplatform.googleapis.com` API
- Regional endpoints (us-central1, europe-west4, etc.)
- Service account needs `aiplatform.user` role
- Billing must be enabled
- Rate limits apply (requests per minute)

---

## Common Commands Quick Reference

### Project Configuration
```bash
# Set project
gcloud config set project PROJECT_ID

# Get current project
gcloud config get-value project

# List projects
gcloud projects list

# Set region/zone
gcloud config set compute/region REGION
gcloud config set compute/zone ZONE
```

### Enable APIs
```bash
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  firestore.googleapis.com \
  secretmanager.googleapis.com
```

### Service Accounts
```bash
# Create
gcloud iam service-accounts create SA_NAME \
  --display-name="Display Name"

# List
gcloud iam service-accounts list

# Delete
gcloud iam service-accounts delete SA_EMAIL
```

### IAM Policy Bindings
```bash
# Add (project-level)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="ROLE"

# Remove (project-level)
gcloud projects remove-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="ROLE"

# Add (resource-level)
gcloud run services add-iam-policy-binding SERVICE \
  --member="serviceAccount:SA_EMAIL" \
  --role="ROLE" \
  --region=REGION
```

### Cloud Run
```bash
# Deploy
gcloud run deploy SERVICE \
  --image=IMAGE_URL \
  --region=REGION \
  --allow-unauthenticated

# List services
gcloud run services list

# Describe service
gcloud run services describe SERVICE --region=REGION

# Delete service
gcloud run services delete SERVICE --region=REGION

# Update service
gcloud run services update SERVICE \
  --service-account=SA_EMAIL \
  --region=REGION
```

### Cloud Build
```bash
# Submit with Dockerfile
gcloud builds submit --tag IMAGE_URL

# Submit with config
gcloud builds submit --config=cloudbuild.yaml

# Submit with buildpacks
gcloud builds submit --pack image=IMAGE_URL

# List builds
gcloud builds list

# View logs
gcloud builds log BUILD_ID
```

### Cloud Storage
```bash
# Create bucket
gsutil mb gs://BUCKET_NAME

# Copy files
gsutil cp FILE gs://BUCKET/
gsutil cp -r DIR gs://BUCKET/

# List
gsutil ls gs://BUCKET/

# Delete
gsutil rm gs://BUCKET/FILE
gsutil rm -r gs://BUCKET/DIR

# Make public
gsutil iam ch allUsers:objectViewer gs://BUCKET
```

---

## Exam Tips Summary

### Architecture Patterns
1. **Microservices**: Cloud Run + Pub/Sub
2. **Event-driven**: Storage → Pub/Sub → Cloud Run
3. **Batch processing**: Cloud Functions + Cloud Scheduler
4. **API Gateway**: Cloud Endpoints + Cloud Run

### Cost Optimization
- Set `--max-instances` to limit spend
- Use appropriate resource limits (CPU/memory)
- Choose right storage class for data
- Delete unused resources promptly
- Use sustained use discounts (Compute Engine)

### Security Best Practices
- Always use service accounts (not user accounts)
- Grant minimum necessary permissions
- Use Secret Manager for credentials
- Never commit secrets to git
- Enable VPC Service Controls for sensitive workloads
- Use private IPs when possible

### Performance
- Deploy in same region as data
- Use regional Artifact Registry
- Enable HTTP/2 and gRPC
- Use connection pooling for databases
- Implement caching strategies
- Use CDN for static content

### Monitoring and Debugging
- Enable Cloud Logging
- Use Cloud Trace for latency analysis
- Set up Cloud Monitoring alerts
- Use Error Reporting for exception tracking
- Check Cloud Build logs for build failures
- Use `gcloud alpha interactive` for command help

---

## Study Resources

### Official Documentation
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [Pub/Sub Documentation](https://cloud.google.com/pubsub/docs)

### Practice
- Qwiklabs: Hands-on labs
- Cloud Skills Boost: Learning paths
- Google Cloud Free Tier: Practice environment

### Exam Guide
- [Professional Cloud Developer Exam Guide](https://cloud.google.com/certification/cloud-developer)

---

**Good luck with your certification! 🎓**

