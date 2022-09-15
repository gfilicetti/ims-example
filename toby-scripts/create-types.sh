#project vars
IMS_BUCKET=ims-script-testing
PROJECT_ID=ims-script-testing
LOCATION=us-west2

#asset vars
COMPLEXTYPE_ID=fxvideo
ASSETTYPE_ID=fxvideofile

#type vars
COMPLEXTYPE_JSON=$(jq -n \
    '{
        "fields": {
            "createDate": {
                "type": "datetime", 
                "required": "true"
            }
        },
        "allowUndefinedFields": "true"
    }' )

ASSETTYPE_JSON=$(jq -n \
    --arg complexType "projects/$PROJECT_ID/locations/$LOCATION/complexTypes/$COMPLEXTYPE_ID" \
    '{
        "metadataConfigs": { 
            "matchMetadata": { 
                "complexType": $complexType, 
                "required": true 
            } 
        }, 
        "indexedFieldConfigs": { 
            "metadata.matchMetadata.createDate": { 
                "expression": "metadata.matchMetadata.createDate" 
                } 
        },
        "sortOrder": {
            "descending": "true",
            "field": "metadata.matchMetadata.createDate"
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
    echo ComplexType $COMPLEXTYPE_ID will be created... 

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
        echo "ComplexType created successfully"
    else 
        echo "Something went wrong creating the ComplexType."
        echo $resp | jq -r '.error'
    fi

else
    echo ComplexType $COMPLEXTYPE_ID already exists.
fi


#get AssetType
resp=$(curl --silent -X GET \
-H "Authorization: Bearer $authToken" \
"https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID")

if [[ $(echo $resp | jq -r '.name' ) != "projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID" ]]
then
    echo "AssetType $ASSETTYPE_ID will be created. (This takes about 200 seconds.)"

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

    #get AssetType
    result=$(curl --silent -X GET \
    -H "Authorization: Bearer $authToken" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID")

    if [[ $(echo $result | jq -r '.name' ) == "projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID" ]]
    then
        echo -n -e "\rAssetType created successfully"
    else 
        echo -n -e "\rSomething went wrong creating the AssetType:"
        echo $resp | jq -r '.error'
    fi
else
    echo AssetType $ASSETTYPE_ID exists.
fi