#!/bin/bash
#set defaults for all assettypes and complextypes in storage bucket

#command line args
ARGS=$@

#project vars
PROJECT_ID=fox-ims-pilot
LOCATION=us-west2

#asset vars
COMPLEXTYPE_ID=newsclip
ASSETTYPE_ID=newsclipfile
# NOTE: ARCHIVE can be one of "kttv", "wfld", "fmn" (aka MovieTone)
ARCHIVE=kttv
PAGE_SIZE=10

#authToken
authToken=$(gcloud auth application-default print-access-token)

#search string
QUERY_JSON=$(jq -n \
                --arg qry "$ARGS" \
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