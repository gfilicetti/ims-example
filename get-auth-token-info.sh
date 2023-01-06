#!/bin/bash
# get-auth-token-info.sh 
# This will print out all the information about the app default access token 
#   (including its expiry time in seconds)

# get the authToken
authToken=$(gcloud auth application-default print-access-token)

printf "===================================\n"
printf "== APP DEFAULT ACCESS TOKEN INFO ==\n" 
printf "===================================\n"
results=$(curl -s -H "Content-Type: application/x-www-form-urlencoded" -d "access_token=$authToken" "https://www.googleapis.com/oauth2/v1/tokeninfo")
echo $results | jq