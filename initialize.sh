#!/bin/bash

#project vars
PROJECT_ID=fox-ims-pilot

printf "=======================================\n"
printf "== INITIALIZING PROJECT FOR IMS APIs ==\n"
printf "=======================================\n"

gcloud projects add-iam-policy-binding \
    --member=serviceAccount:cloud-control2-media-asset-clh@system.gserviceaccount.com \
    --role=roles/storage.objectViewer ${PROJECT_ID}

gcloud projects add-iam-policy-binding \
    --member=serviceAccount:cloud-control2-media-asset-backend@system.gserviceaccount.com \
    --role=roles/storage.objectViewer ${PROJECT_ID}

