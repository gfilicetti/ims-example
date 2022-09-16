#!/bin/bash
# get-types.sh COMPLEX_TYPE ASSET_TYPE [LOCATION] [PROJECT_ID]
# Retrieve complex and asset type objects and print them to screen

#asset vars
COMPLEXTYPE_ID=${1:-"newsclip"}
ASSETTYPE_ID=${2:-"newsclipfile"}

#project vars
LOCATION=${3:-"us-west2"}
PROJECT_ID=${4:-$(gcloud config get project)}

#authToken
authToken=$(gcloud auth application-default print-access-token)

#get ComplexType
printf "=============================\n"
printf "== GETTING $COMPLEXTYPE_ID ==\n" 
printf "=============================\n"
curl --silent -X GET \
-H "Authorization: Bearer $authToken" \
"https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/complexTypes/$COMPLEXTYPE_ID"

#get AssetType
printf "===========================\n"
printf "== GETTING $ASSETTYPE_ID ==\n" 
printf "===========================\n"
curl --silent -X GET \
-H "Authorization: Bearer $authToken" \
"https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID"
