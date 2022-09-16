#!/bin/bash
# ingest-assets.sh GCS_BUCKET_NAME ARCHIVE ASSET_TYPE [LOCATION] [PROJECT_ID]
# Ingest all the assets in the given GCS bucket in the folder name that matches ARCHIVE

#asset vars
IMS_BUCKET=${1:-"ims-assets-2"}
ARCHIVE=${2:-"kttv"}
ASSETTYPE_ID=${3:-"newsclipfile"}

#project vars
LOCATION=${4:-"us-central1"}
PROJECT_ID=${5:-$(gcloud config get project)}

#authToken
authToken=$(gcloud auth application-default print-access-token)

i=1

printf "============================\n"
printf "== ADDING ASSETS TO INDEX ==\n" 
printf "============================\n"
for curFile in $(gsutil ls -r gs://$IMS_BUCKET/$ARCHIVE/*)
do 
    STORAGE_INPUT_VIDEO=${curFile#gs://$IMS_BUCKET/$ARCHIVE/}
    ASSET_ID=$(printf "%04g$i")
    CREATE_TIME=$(gsutil ls -l gs://$IMS_BUCKET/$ARCHIVE/$STORAGE_INPUT_VIDEO | awk {'print $2'} | head -c -2)

    # if the current file is just a folder, then skip to the next file
    [[ ! $STORAGE_INPUT_VIDEO ]] && continue

    printf "Processing file: ${curFile}\n"
    printf "Ingesting with: \n"
    printf "\tassetID: ${ASSET_ID} \n"
    printf "\tobject: $ARCHIVE/$STORAGE_INPUT_VIDEO \n"
    printf "\tuploadDate: ${CREATE_TIME} \n"
    printf "\tarchive: ${ARCHIVE}\n"

    JSON_STRING=$(jq -n \
                    --arg bn "$IMS_BUCKET" \
                    --arg on "$ARCHIVE/$STORAGE_INPUT_VIDEO" \
                    --arg ct "$CREATE_TIME" \
                    --arg ar "$ARCHIVE" \
                    '{ "metadata":
                    { 
                        "video_file": { 
                            "bucket": $bn, 
                            "object": $on 
                        },
                        "clipMetadata": { 
                            "uploadDate": $ct,
                            "archive": $ar
                        }
                    } }' )

    ((i+=1))

    printf "Making API request with JSON: \n$JSON_STRING\n"

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

