#!/bin/bash
# query-assets.sh "QUERY STRING" PAGE_SIZE, OUTPUT_FORMAT ASSET_TYPE [LOCATION] [PROJECT_ID]
# Queries IMS using the query string. 
# QUERY STRING: Must enclose the query in quotes because it is only the first parameter
# PAGE_SIZE: The number of results to return per API call
# OUTPUT_FORMAT: One of:
#   Visual: output in a readable format
#   CSV: output as CSV
#   HTML: output as HTML
#   Json: output the raw Json output from the API call

#command line args
QUERY=${1}

# how many results to return
PAGE_SIZE=${2:-2000}

# output format
# can be one of: Visual, CSV, Json
OUTPUT_FORMAT=${3:-"Visual"}

#asset vars
ASSETTYPE_ID=${4:-"newsclipfile"}

#project vars
LOCATION=${5:-"us-central1"}
PROJECT_ID=${6:-$(gcloud config get project)}

# get the authToken
authToken=$(gcloud auth application-default print-access-token)

# colour constants
# https://www.shellhacks.com/bash-colors/
# https://linuxhint.com/bash_test_background_colors/
RED=$'\e[1;31m'
GREEN=$'\e[1;32m'
YELLOW=$'\e[1;33m'
WHITE=$'\e[1;37m'
RESET=$'\e[0m'

# print function for stderr (saves our stdout to CSV output only)
printerr() { printf "%s\n" "$*" >&2; }

#conversion function for seconds to hh:mm:ss
convertAndPrintSeconds() {
    local totalSeconds=$1;
    local seconds=$((totalSeconds%60));
    local minutes=$((totalSeconds/60%60));
    local hours=$((totalSeconds/60/60));
    printf '%02d:' $hours;
    printf '%02d:' $minutes;
    printf '%02d\n' $seconds;
}

printVisual() {
    local assetId=$1;
    local assetBucket=$2;
    local assetFileName=$3;
    local startTime=$4;
    local endTime=$5;

    # print asset info
    printf "===============\n";
    printf "Asset Id: ${assetId}\n";
    printf "===============\n";

    # print bucket & filename
    printf "Bucket: ${assetBucket}\n";
    printf "Asset File: ${assetFileName}\n";
    printf "===============\n";

    # convert start and end times from total seconds to mm:ss and output them
    printf "Segment: ${GREEN}${startTime}${RESET} ${WHITE}--->${RESET} ${RED}${endTime}${RESET}\n\n";
}

printCSV() {
    local assetId=$1;
    local assetBucket=$2;
    local assetFileName=$3;
    local startTime=$4;
    local endTime=$5;
    local startSeconds=$6;
    local endSeconds=$7;
    local startRaw=$8;
    local endRaw=$9;

    # print the header only once
    if [[ ! $headerPrinted ]] 
    then
        printf "id,bucket,filename,start_time,end_time,start_seconds,end_seconds,start_raw,end_raw\n"
        headerPrinted="true"
    fi

    # print the current result
    printf "${assetId},${assetBucket},${assetFileName},${startTime},${endTime},${startSeconds},${endSeconds},${startRaw},${endRaw}\n"

}

printHTML() {
    local assetId=$1;
    local assetBucket=$2;
    local assetFileName=$3;
    local startTime=$4;
    local endTime=$5;
    local startSeconds=$6;
    local endSeconds=$7;
    local startRaw=$8;
    local endRaw=$9;

    # print the header only once
    if [[ ! $headerPrinted ]] 
    then
        printf "
<html>
    <head>
        <!-- CSS only -->
        <link href='https://cdn.jsdelivr.net/npm/bootstrap@5.2.2/dist/css/bootstrap.min.css' rel='stylesheet' integrity='sha384-Zenh87qX5JnK2Jl0vWa8Ck2rdkQ2Bzep5IDxbcnCeuOxjzrPF/et3URy9Bv1WTRi' crossorigin='anonymous'>
    </head>
    <body>
        <h3>'${QUERY}'</h3>
        <table class='table'>
            <thead>
                <tr>
                    <th>id</th>
                    <th>bucket</th>
                    <th>filename</th>
                    <th>start_time</th>
                    <th>end_time</th>
                    <th>start_seconds</th>
                    <th>end_seconds</th>
                    <th>start_raw</th>
                    <th>end_raw</th>
                </tr>
            </thead>
            <tbody>\n"

        headerPrinted="true"

    fi

    # print the current result
    printf "
                <tr>
                    <td>${assetId}</td>
                    <td>${assetBucket}</td>
                    <td><a href='https://storage.cloud.google.com/${assetBucket}/${assetFileName}'>${assetFileName}</a></td>
                    <td>${startTime}</td>
                    <td>${endTime}</td>
                    <td>${startSeconds}</td>
                    <td>${endSeconds}</td>
                    <td>${startRaw}</td>
                    <td>${endRaw}</td>
                </tr>\n"
                        
}

printJson() {
    # we don't need any parameters, just assume the query was already called.
    echo $queryResults | jq

    # we know we only need to output the raw results once, so lets short-circuit the loop
    break
}

#search string
QUERY_JSON=$(jq -n \
                --arg qry "$QUERY" \
                --arg ps "$PAGE_SIZE" \
                '{ 
                    "query": $qry,
                    "pageSize": $ps
                }' )

printerr "====================="
printerr "== QUERYING ASSETS =="
printerr "====================="
printerr "$QUERY_JSON"

queryResults=$(curl -s -X POST \
    -H "Authorization: Bearer $authToken" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "$QUERY_JSON" \
    "https://mediaasset.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/assetTypes/$ASSETTYPE_ID:search")
    
# use outer parens to put results into an array
assetResults=($(echo $queryResults | jq -rc '.items[].asset'))
startSegmentResults=($(echo $queryResults | jq -rc '.items[].segments[] | .startOffset'))
endSegmentResults=($(echo $queryResults | jq -rc '.items[].segments[] | .endOffset'))

# all the arrays will be the same length, so just get the length of one of them
resultLength=${#assetResults[@]}

# print number of results
printerr "========================="
printerr "== NUM OF RESULTS: $(printf '%03d' ${resultLength}) =="
printerr "========================="

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

    # make a bunch of conversions to the time segments
    # raw has format of fractional seconds plus 's' suffix
    # eg: 786.226432s
    startRaw=${startSegmentResults[$curIndex]}
    endRaw=${endSegmentResults[$curIndex]}

    # now we lop off the 's' suffix and lop off the fractional seconds
    # first we remove the suffix, then we kill the decimal and all numbers after it
    startSeconds=${startRaw%"s"}
    startSeconds=${startSeconds%"."*[0-9]}
    endSeconds=${endRaw%"s"}
    endSeconds=${endSeconds%"."*[0-9]}

    # now we take the seconds and convert to a readable format: hh:mm:ss
    startTime=$(convertAndPrintSeconds ${startSeconds})
    endTime=$(convertAndPrintSeconds ${endSeconds})

    # the OUTPUT_FORMAT variable is used to construct the name of the printing function we need to call:
    # printVisual, printCSV or printJson
    print$OUTPUT_FORMAT ${assetId} ${assetBucket} ${assetFileName} ${startTime} ${endTime} ${startSeconds} ${endSeconds} ${startRaw} ${endRaw}

done

# if we are HTML output, we need to output the footer
if [ $OUTPUT_FORMAT == "HTML" ] 
then
    printf "
            </tbody>
        </table>
    </body>
</html>\n"
fi
    
