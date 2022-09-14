#!/bin/bash

#project vars
IMS_BUCKET=ims-assets-1
PROJECT_ID=fox-ims-pilot
LOCATION=us-west2

#asset vars
COMPLEXTYPE_ID=newsclip
ASSETTYPE_ID=newsclipfile

#authToken
authToken=$(gcloud auth application-default print-access-token)

# delete AssetType
printf "============================\n"
printf "== REMOVING $ASSETTYPE_ID ==\n" 
printf "============================\n"
curl --silent -X DELETE \
-H "Authorization: Bearer $authToken" \
"https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID"

# delete ComplexType
printf "==============================\n"
printf "== REMOVING $COMPLEXTYPE_ID ==\n"
printf "==============================\n"
curl --silent -X DELETE \
-H "Authorization: Bearer $authToken" \
"https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/complexTypes/$COMPLEXTYPE_ID"

