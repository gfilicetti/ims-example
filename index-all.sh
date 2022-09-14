#!/bin/bash
#set defaults for all assettypes and complextypes in storage bucket

#project vars
IMS_BUCKET=ims-assets-1
PROJECT_ID=fox-ims-pilot
LOCATION=us-west2

#asset vars
COMPLEXTYPE_ID=newsclip
ASSETTYPE_ID=newsclipfile
# NOTE: ARCHIVE can be one of "KTTV", "WFLD", "FMN" (aka MovieTone)
ARCHIVE=FMN

#authToken
authToken=$(gcloud auth application-default print-access-token)

i=1

#index all assets as $COMPLEX_TYPE
printf "============================\n"
printf "== ADDING ASSETS TO INDEX ==\n" 
printf "============================\n"
for curFile in $(gsutil ls -r gs://$IMS_BUCKET/*)
do 
    STORAGE_INPUT_VIDEO=${curFile#gs://$IMS_BUCKET/}
    ASSET_ID=$(printf "%04g$i")
    CREATE_TIME=$(gsutil ls -l gs://$IMS_BUCKET/$STORAGE_INPUT_VIDEO | awk {'print $2'} | head -c -2)

    echo "Found file: ${curFile}\n"
    echo "Indexing with AssetID: ${ASSET_ID}, uploadDate: ${CREATE_TIME} and archive: ${ARCHIVE}\n"

    JSON_STRING=$(jq -n \
                    --arg bn "$IMS_BUCKET" \
                    --arg on "$STORAGE_INPUT_VIDEO" \
                    --arg ct "$CREATE_TIME" \
                    --arg ar "$ARCHIVE" \
                    '{ "metadata":
                    { 
                        "video_file": { 
                        "bucket": $bn, 
                        "object": $on 
                        },
                        "clipMetadata": { 
                            "uploadDate": $ct
                            "archive": $ar
                        }
                    } }' )

    # echo $JSON_STRING

    ((i+=1))

    curl -X POST \
    -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
    -H "Content-Type: application/json; charset=utf-8" \
    -d  "$JSON_STRING" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID/assets?asset_id=$ASSET_ID"
done

printf "===============================\n"
printf "== CHECKING STATUS ON ASSETS ==\n"
printf "===============================\n"

for (( j = $i-1; j>0; j--)) 
do
    ASSET_ID=$(printf "%04g$j")

    curl -X GET -H "Authorization: Bearer $authToken" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID/assets/$ASSET_ID/actions"
done

