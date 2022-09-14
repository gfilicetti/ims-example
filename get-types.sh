#!/bin/bash

#project vars
PROJECT_ID=fox-ims-pilot
LOCATION=us-west2

#asset vars
COMPLEXTYPE_ID=newsclip
ASSETTYPE_ID=newsclipfile

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
