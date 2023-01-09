#!/bin/bash
# clean-gcs-files.sh GCS_BUCKET_NAME ARCHIVE
# Remove spaces from the name of any assets in the given GCS bucket in the folder name that matches ARCHIVE

# cmd line vars
BUCKET=${1:-"ims-assets-2"}
ARCHIVE=${2:-"news"}

# set the delimiter to newline only, ignore the backspace
# https://www.baeldung.com/linux/ifs-shell-variable
# https://stackoverflow.com/questions/16831429/when-setting-ifs-to-split-on-newlines-why-is-it-necessary-to-include-a-backspac
IFS=$(echo -en "\n\b")

printf "==================================================\n"
printf "== CLEAN FILE NAMES IN BUCKET: $BUCKET/$ARCHIVE ==\n" 
printf "==================================================\n"
for curFile in $(gsutil ls -r gs://$BUCKET/$ARCHIVE/*)
do 
    # skip if the curFile ends in a slash. That means it's a directory.
    [[ $curFile == *\/ ]] && continue

    # only work on files that contain a space
    if [[ $curFile == *\ * ]]
    then
        ORIGINAL_URL=$curFile
        FIXED_URL=${curFile// /_}

        printf "================================\n"
        printf "== REMOVING SPACES FROM FILE: ==\n"
        printf "================================\n"
        printf "Original Name: \t${ORIGINAL_URL} \n"
        printf "Fixed Name: \t${FIXED_URL} \n"
        
        # make the call to gsutil to rename the file
        gsutil -q mv $ORIGINAL_URL $FIXED_URL

        printf "== WAITING FOR 1s ==\n\n"
        sleep 1
    fi
done
