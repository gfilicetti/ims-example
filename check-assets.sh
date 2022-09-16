#!/bin/bash
# check-assets.sh NUMBER_OF_ASSETS ASSET_TYPE [LOCATION] [PROJECT_ID]
# Check the status on the assets of the given type. Only check for the number of assets given.

#asset vars
NUM_ASSETS=${1:-"2"}
ASSETTYPE_ID=${2:-"newsclipfile"}

#project vars
LOCATION=${3:-"us-west2"}
PROJECT_ID=${4:-$(gcloud config get project)}

#authToken
authToken=$(gcloud auth application-default print-access-token)

printf "===============================\n"
printf "== CHECKING STATUS ON ASSETS ==\n"
printf "===============================\n"

for (( j = ${NUM_ASSETS}; j>0; j--)) 
do
    ASSET_ID=$(printf "%04g$j")

    curl -X GET -H "Authorization: Bearer $authToken" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID/assets/$ASSET_ID/actions"
done

