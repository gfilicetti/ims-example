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
    # get only the path of the file, don't need bucket name
    STORAGE_INPUT_VIDEO=${curFile#gs://$IMS_BUCKET/$ARCHIVE/}

    # create a sequential id that's always 4 digits wide and prefaced by the archive name
    ASSET_ID="${ARCHIVE}-$(printf "%04d" $i)"

    # use the create time of the file in storage
    CREATE_TIME=$(gsutil ls -l gs://$IMS_BUCKET/$ARCHIVE/$STORAGE_INPUT_VIDEO | awk {'print $2'} | head -c -2)

    # if the current file is just a folder, then skip to the next file
    [[ ! $STORAGE_INPUT_VIDEO ]] && continue

    printf "=================================\n"
    printf "== Processing file: ${curFile} ==\n"
    printf "=================================\n"
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

    # output the request JSON doc before making the call
    # printf "Making API request with JSON: \n$JSON_STRING\n"

    printf "== CALLING API ==\n"

    curl -X POST \
    -H "Authorization: Bearer $authToken" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d  "$JSON_STRING" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID/assets?asset_id=$ASSET_ID"

    printf "== WAITING FOR 1s ==\n"
    sleep 1

done