#!/bin/bash
# check-assets.sh NUMBER_OF_ASSETS ASSET_TYPE [LOCATION] [PROJECT_ID]
# Check the status on the assets of the given type. Only check for the number of assets given.

#asset vars
NUM_ASSETS=${1:-"2"}
ARCHIVE=${2:-"news"}
ASSETTYPE_ID=${3:-"newsclipfile"}

#project vars
LOCATION=${4:-"us-central1"}
PROJECT_ID=${5:-$(gcloud config get project)}

#authToken
authToken=$(gcloud auth application-default print-access-token)

printf "===============================\n"
printf "== CHECKING STATUS ON ASSETS ==\n"
printf "===============================\n"

for i in $(seq ${NUM_ASSETS})
do
    ASSET_ID="${ARCHIVE}-$(printf "%04d" $i)"

    curl -s -X GET -H "Authorization: Bearer $authToken" \
        "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID/assets/$ASSET_ID/actions" |
            jq -r '.actions[] | select (.name | contains("media_indexer")) | {name,state} | join(" --> ")' 
done