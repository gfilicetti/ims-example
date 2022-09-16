#!/bin/bash
# initialize IMS for this project by granting IAM pers to read storage

#project vars
PROJECT_ID=${1:-$(gcloud config get project)}

printf "===========================\n"
printf "== ENABLE THE MEDIA APIs ==\n"
printf "===========================\n"
gcloud services enable mediaasset.googleapis.com

printf "=======================================\n"
printf "== INITIALIZING PROJECT FOR IMS APIs ==\n"
printf "=======================================\n"
gcloud projects add-iam-policy-binding \
    --member=serviceAccount:cloud-control2-media-asset-clh@system.gserviceaccount.com \
    --role=roles/storage.objectViewer ${PROJECT_ID}

gcloud projects add-iam-policy-binding \
    --member=serviceAccount:cloud-control2-media-asset-backend@system.gserviceaccount.com \
    --role=roles/storage.objectViewer ${PROJECT_ID}

