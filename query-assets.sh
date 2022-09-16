#!/bin/bash
# query-assets.sh "QUERY STRING" ASSET_TYPE [LOCATION] [PROJECT_ID]
# Queries IMS using the query string. Query string is expected as the first parameter 
# so you must enclose the query in quotes

#command line args
QUERY=${1}

#asset vars
ASSETTYPE_ID=${2:-"newsclipfile"}

#project vars
LOCATION=${3:-"us-central1"}
PROJECT_ID=${4:-$(gcloud config get project)}

# NOTE: ARCHIVE can be one of "kttv", "wfld", "fmn" (aka MovieTone)
ARCHIVE=kttv
PAGE_SIZE=10

#authToken
authToken=$(gcloud auth application-default print-access-token)

#search string
QUERY_JSON=$(jq -n \
                --arg qry "$QUERY" \
                --arg ps "$PAGE_SIZE" \
                '{ 
                    "query": $qry,
                    "pageSize": $ps
                }' )

echo $QUERY_JSON

curl -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "$QUERY_JSON" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID:search"