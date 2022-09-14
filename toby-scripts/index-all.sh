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

i=1

#index all assets as $COMPLEX_TYPE
for f in $(gsutil ls -r gs://$IMS_BUCKET/*)
do 

 STORAGE_INPUT_VIDEO=${f#gs://$IMS_BUCKET/}
 ASSET_ID=$(printf "%04g$i")
 CREATE_TIME=$(gsutil ls -l gs://$IMS_BUCKET/$STORAGE_INPUT_VIDEO | awk {'print $2'} | head -c -2)

 echo "Found file: " $f "using AssetID: " $ASSET_ID " and CreateTime: " $CREATE_TIME
 
 JSON_STRING=$(jq -n \
                  --arg bn "$IMS_BUCKET" \
                  --arg on "$STORAGE_INPUT_VIDEO" \
                  --arg ct "$CREATE_TIME" \
                  '{ "metadata":
                    { 
                        "video_file": { 
                        "bucket": $bn, 
                        "object": $on 
                        },
                        "matchMetadata": { 
                            "createDate": $ct
                        }
                    } }' )

                  #echo $JSON_STRING
 ((i+=1))

#curl -X POST \
#-H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
#-H "Content-Type: application/json; charset=utf-8" \
#-d  "$JSON_STRING" \
#"https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID/assets?asset_id=$ASSET_ID"

done

for (( j = $i-1; j>0; j--)) 
do
    printf "%04g$j\n"

#get actions for asset
#ASSET_ID="00001"

curl -X GET -H "Authorization: Bearer $authToken" \
"https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID/assets/$(printf "%04g$j")/actions"
done