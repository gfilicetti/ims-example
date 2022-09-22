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

# colour constants
# https://www.shellhacks.com/bash-colors/
# https://linuxhint.com/bash_test_background_colors/
RED=$'\e[1;31m'
GREEN=$'\e[1;32m'
YELLOW=$'\e[1;33m'
RESET=$'\e[0m'

#conversion function for seconds to mm:ss
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
    -H "Authorization: Bearer $authToken" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "$QUERY_JSON" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID:search")
    
# print raw results
printf "===================\n"
printf "== QUERY RESULTS ==\n"
printf "===================\n"
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
    # our loop is 1 based, we need 0 based for the array so subtract 1 from the loop index
    ((curIndex=i-1))

    # to get the asset id, we need to take only the last element of the assetPath
    # however, to do this in bash, which doesn't do non-greedy regex, we need to loop and cut
    # off pieces of the assetPath until we're down to the last one
    assetPath=${assetResults[$curIndex]}
    assetId=$assetPath
    regex='/(.*)$'
    # loop and repeatedly cut the assetPath down using the '/' delimiter (see regex)
    while [[ $assetId =~ $regex ]]; do
        assetId=${BASH_REMATCH[1]}
    done

    # call using assetId to get asset information
    assetResults=$(curl -s -X GET \
        -H "Authorization: Bearer $authToken" \
        "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID/assets/$assetId")

    assetFileName=$(echo $assetResults | jq -rc '.metadata.video_file.object')
    assetBucket=$(echo $assetResults | jq -rc '.metadata.video_file.bucket')

    # lop off any fractional seconds, we don't need them
    startTime=${startSegmentResults[$curIndex]%"."*[0-9]"s"}
    endTime=${endSegmentResults[$curIndex]%"."*[0-9]"s"}

    # print asset info
    printf "==========\n"
    printf "Asset Id: ${assetId}\n"
    printf "==========\n"

    # print bucket & filename
    printf "Bucket: ${assetBucket}\n"
    printf "Asset File: ${assetFileName}\n"
    printf "==========\n"

    # convert start and end times from total seconds to mm:ss and output them
    printf "Segment: ${GREEN}$(convertAndPrintSeconds ${startTime})${RESET} --> ${RED}$(convertAndPrintSeconds $endTime)${RESET}\n\n"

done
