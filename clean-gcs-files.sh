#!/bin/bash
# clean-gcs-files.sh GCS_BUCKET_NAME ARCHIVE [LOCATION] [PROJECT_ID]
# Ingest all the assets in the given GCS bucket in the folder name that matches ARCHIVE

# cmd line vars
BUCKET=${1:-"ims-assets-2"}
ARCHIVE=${2:-"news"}

#project vars
LOCATION=${3:-"us-central1"}
PROJECT_ID=${4:-$(gcloud config get project)}

# set the delimiter to newline only, ignore the backspace
# https://www.baeldung.com/linux/ifs-shell-variable
# https://stackoverflow.com/questions/16831429/when-setting-ifs-to-split-on-newlines-why-is-it-necessary-to-include-a-backspac
IFS=$(echo -en "\n\b")

printf "==================================================\n"
printf "== CLEAN FILE NAMES IN BUCKET: $BUCKET/$ARCHIVE ==\n" 
printf "==================================================\n"
for curFile in $(gsutil ls -r gs://$BUCKET/$ARCHIVE/*)
do 
	printf "$curFile\n"
    # get only the path of the file, don't need bucket name
    STORAGE_INPUT_VIDEO=${curFile#gs://$BUCKET/$ARCHIVE/}
    	printf "$STORAGE_INPUT_VIDEO\n"
	continue 

    # create a sequential id that's always 4 digits wide and prefaced by the archive name
    ASSET_ID="${ARCHIVE}-$(printf "%04d" $i)"

    # if the current file is just a folder, then skip to the next file
    [[ ! $STORAGE_INPUT_VIDEO ]] && continue

    printf "=================================\n"
    printf "== Processing file: ${curFile} ==\n"
    printf "=================================\n"
    printf "Ingesting with: \n"
    printf "\tassetID: ${ASSET_ID} \n"
    printf "\tobject: $ARCHIVE/$STORAGE_INPUT_VIDEO \n"
    printf "\tarchive: ${ARCHIVE}\n"

    printf "== WAITING FOR 1s ==\n"
    sleep 1

done
