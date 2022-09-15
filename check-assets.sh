#!/bin/bash

#project vars
PROJECT_ID=fox-ims-pilot

#asset vars
COMPLEXTYPE_ID=newsclip
ASSETTYPE_ID=newsclipfile
# NOTE: ARCHIVE can be one of "kttv", "wfld", "fmn" (aka MovieTone)
ARCHIVE=fmn

# number of assets
NUM_ASSETS=2

#authToken
authToken=$(gcloud auth application-default print-access-token)

printf "===============================\n"
printf "== CHECKING STATUS ON ASSETS ==\n"
printf "===============================\n"

for (( j = ${NUM_ASSETS}-1; j>0; j--)) 
do
    ASSET_ID=$(printf "%04g$j")

    curl -X GET -H "Authorization: Bearer $authToken" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID/assets/$ASSET_ID/actions"
done

