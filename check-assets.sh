#!/bin/bash

#project vars
# IMS_BUCKET=ims-assets-1
# PROJECT_ID=fox-ims-pilot
IMS_BUCKET=ims-script-testing
PROJECT_ID=ims-script-testing
LOCATION=us-west2

#asset vars
# COMPLEXTYPE_ID=newsclip
# ASSETTYPE_ID=newsclipfile
# NOTE: ARCHIVE can be one of "KTTV", "WFLD", "FMN" (aka MovieTone)
# ARCHIVE=FMN
COMPLEXTYPE_ID=fxvideo
ASSETTYPE_ID=fxvideofile

#authToken
authToken=$(gcloud auth application-default print-access-token)

# number of assets
NUM_ASSETS=5

printf "===============================\n"
printf "== CHECKING STATUS ON ASSETS ==\n"
printf "===============================\n"

for (( j = ${NUM_ASSETS}-1; j>0; j--)) 
do
    ASSET_ID=$(printf "%04g$j")

    curl -X GET -H "Authorization: Bearer $authToken" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID/assets/$ASSET_ID/actions"
done

