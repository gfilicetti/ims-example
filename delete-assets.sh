#!/bin/bash
# delete-assets.sh NUMBER_OF_ASSETS ASSET_TYPE [LOCATION] [PROJECT_ID]
# Delete assets of the given type. Only delete the number of assets given.

#asset vars
NUM_ASSETS=${1:-"2"}
ARCHIVE=${2:-"kttv"}
ASSETTYPE_ID=${3:-"newsclipfile"}

#project vars
LOCATION=${4:-"us-central1"}
PROJECT_ID=${5:-$(gcloud config get project)}

#authToken
authToken=$(gcloud auth application-default print-access-token)

printf "=====================\n"
printf "== DELETING ASSETS ==\n"
printf "=====================\n"

for (( j = ${NUM_ASSETS}; j>0; j--)) 
do
    ASSET_ID="${ARCHIVE}-$(printf "%04d" $j)"

    curl -X DELETE -H "Authorization: Bearer $authToken" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID/assets/$ASSET_ID"
done

