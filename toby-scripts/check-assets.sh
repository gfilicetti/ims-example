#!/bin/bash
#set defaults for all assettypes and complextypes in storage bucket

#project vars
IMS_BUCKET=ims-script-testing
PROJECT_ID=ims-script-testing
LOCATION=us-west2

#asset vars
COMPLEXTYPE_ID=fxvideo
ASSETTYPE_ID=fxvideofile

#authToken
authToken=$(gcloud auth application-default print-access-token)

numOfAssets=5

#index all assets as $COMPLEX_TYPE
for (( j = $numOfAssets; j>0; j--)) 
do
    printf "%04g$j\n"

#get actions for asset
#ASSET_ID="00001"

curl -X GET -H "Authorization: Bearer $authToken" \
"https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID/assets/$(printf "%04g$j")/actions"
done
