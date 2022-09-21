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

# how many results to return
PAGE_SIZE=10

# get the authToken
authToken=$(gcloud auth application-default print-access-token)

#conversion function for seconds
convertAndPrintSeconds() {
    local totalSeconds=$1;
    local seconds=$((totalSeconds%60));
    local minutes=$((totalSeconds/60%60));
    local hours=$((totalSeconds/60/60));
    printf '%02d:' $hours;
    printf '%02d:' $minutes;
    printf '%02d\n' $seconds;
}

#search string
QUERY_JSON=$(jq -n \
                --arg qry "$QUERY" \
                --arg ps "$PAGE_SIZE" \
                '{ 
                    "query": $qry,
                    "pageSize": $ps
                }' )

printf "=====================\n"
printf "== QUERYING ASSETS ==\n"
printf "=====================\n"
printf "$QUERY_JSON\n"

queryResults=$(curl -s -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "$QUERY_JSON" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID:search")
    
# print raw results
echo $queryResults | jq

# use outer parens to put results into an array
assetResults=($(echo $queryResults | jq -rc '.items[].asset'))
startSegmentResults=($(echo $queryResults | jq -rc '.items[].segments[] | .startOffset'))
endSegmentResults=($(echo $queryResults | jq -rc '.items[].segments[] | .endOffset'))

# all the arrays will be the same length, so just get one of them
resultLength=${#assetResults[@]}

# loop through the number of results (in numbers)
for i in $(seq $resultLength)
do
    # our loop is 1 based, we need 0 based for the array
    curIndex=i-1

    # lop off any fractional seconds, we don't need them
    startTime=${startSegmentResults[$curIndex]%"."*[0-9]"s"}
    endTime=${endSegmentResults[$curIndex]%"."*[0-9]"s"}

    # print the asset id
    printf "Asset: ${assetResults[$curIndex]}\n"

    # convert start and end times from total seconds to mm:ss and output them
    printf "Segment: $(convertAndPrintSeconds $startTime) --> $(convertAndPrintSeconds $endTime)\n"

done
