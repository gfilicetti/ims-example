#!/bin/bash
# delete-types.sh COMPLEX_TYPE ASSET_TYPE [LOCATION] [PROJECT_ID]
# Delete the complex and asset types specified

#asset vars
COMPLEXTYPE_ID=${1:-"newsclip"}
ASSETTYPE_ID=${2:-"newsclipfile"}

#project vars
LOCATION=${3:-"us-west2"}
PROJECT_ID=${4:-$(gcloud config get project)}

#authToken
authToken=$(gcloud auth application-default print-access-token)

# delete AssetType
printf "============================\n"
printf "== REMOVING $ASSETTYPE_ID ==\n" 
printf "============================\n"
curl --silent -X DELETE \
-H "Authorization: Bearer $authToken" \
"https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID"

# sleep for a bit for AssetType to be fully removed
sleep 5

# delete ComplexType
printf "==============================\n"
printf "== REMOVING $COMPLEXTYPE_ID ==\n"
printf "==============================\n"
curl --silent -X DELETE \
-H "Authorization: Bearer $authToken" \
"https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/complexTypes/$COMPLEXTYPE_ID"

