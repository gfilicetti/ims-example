#!/bin/bash

#project vars
IMS_BUCKET=ims-assets-1
PROJECT_ID=fox-ims-pilot
LOCATION=us-west2

#asset vars
COMPLEXTYPE_ID=newsclip
ASSETTYPE_ID=newsclipfile

#type vars
# NOTE: archive field can be one of "KTTV", "WFLD", "FMN" (aka MovieTone)
COMPLEXTYPE_JSON=$(jq -n \
    '{
        "fields": {
            "uploadDate": {
                "type": "datetime", 
                "required": "true"
            },
            "archive": {
                "type": "string", 
                "required": "true"
            }
        },
        "allowUndefinedFields": "true"
    }' )

ASSETTYPE_JSON=$(jq -n \
    --arg complexType "projects/$PROJECT_ID/locations/$LOCATION/complexTypes/$COMPLEXTYPE_ID" \
    '{
        "metadataConfigs": { 
            "clipMetadata": { 
                "complexType": $complexType, 
                "required": true 
            } 
        }, 
        "indexedFieldConfigs": { 
            "metadata.clipMetadata.uploadDate": { 
                "expression": "metadata.clipMetadata.uploadDate" 
            } 
        },
        "sortOrder": {
            "descending": "true",
            "field": "metadata.clipMetadata.uploadDate"
        }, 
        "mediaType": "VIDEO" }' )

#authToken
authToken=$(gcloud auth application-default print-access-token)

#get ComplexType
resp=$(curl --silent -X GET \
-H "Authorization: Bearer $authToken" \
"https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/complexTypes/$COMPLEXTYPE_ID")

if [[ $(echo $resp | jq -r '.name') != "projects/$PROJECT_ID/locations/$LOCATION/complexTypes/$COMPLEXTYPE_ID" ]]
then
    printf "==========================================\n"
    printf "== CREATING COMPLEXTYPE $COMPLEXTYPE_ID ==\n" 
    printf "==========================================\n"

    #create ComplexType
    curl --silent -X POST \
    -H "Authorization: Bearer $authToken" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "$COMPLEXTYPE_JSON" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/complexTypes?complex_type_id=$COMPLEXTYPE_ID"

    sleep 1

    #get ComplexType
    resp=$(curl --silent -X GET \
    -H "Authorization: Bearer $authToken" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/complexTypes/$COMPLEXTYPE_ID")

    if [[ $(echo $resp | jq -r '.name') == "projects/$PROJECT_ID/locations/$LOCATION/complexTypes/$COMPLEXTYPE_ID" ]]
    then
        printf "==========================================\n"
        printf "== $COMPLEXTYPE_ID CREATED SUCCESSFULLY ==\n" 
        printf "==========================================\n"
    else 
        printf "=====================================\n"
        printf "== ERROR CREATING $COMPLEXTYPE_ID  ==\n"
        printf "=====================================\n"
        echo $resp | jq -r '.error'
    fi

else
    printf "====================================\n"
    printf "== $COMPLEXTYPE_ID ALREADY EXISTS ==\n" 
    printf "====================================\n"
fi


#get AssetType
resp=$(curl --silent -X GET \
-H "Authorization: Bearer $authToken" \
"https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID")

if [[ $(echo $resp | jq -r '.name' ) != "projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID" ]]
then
    printf "======================================\n"
    printf "== CREATING ASSETTYPE $ASSETTYPE_ID ==\n" 
    printf "======================================\n"

    #create AssetType
    resp=$(curl --silent -X POST \
    -H "Authorization: Bearer $authToken" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "$ASSETTYPE_JSON" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes?asset_type_id=$ASSETTYPE_ID")

    OPERATION_ID=$(echo $resp | jq -r '.name |= split("/") | .name[-1]')

    while [[ $(echo $resp | jq -r '.done') != "true" ]]; do 
        echo -n -e "\rcreateAsset is processing your request [$SECONDS seconds]..."
        resp=$(curl --silent -X GET \
        -H "Authorization: Bearer $authToken" \
        "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/operations/$OPERATION_ID")
        sleep 7
    done

    echo -e "\n"

    #get AssetType
    result=$(curl --silent -X GET \
    -H "Authorization: Bearer $authToken" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID")

    if [[ $(echo $result | jq -r '.name' ) == "projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID" ]]
    then
        printf "========================================\n"
        printf "== $ASSETTYPE_ID CREATED SUCCESSFULLY ==\n" 
        printf "========================================\n"
    else 
        printf "==================================\n"
        printf "== ERROR CREATING $ASSETTYPE_ID ==\n"
        printf "==================================\n"
        echo $resp | jq -r '.error'
    fi
else
    printf "==================================\n"
    printf "== $ASSETTYPE_ID ALREADY EXISTS ==\n" 
    printf "==================================\n"
fi

