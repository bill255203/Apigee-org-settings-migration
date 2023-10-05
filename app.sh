#!/bin/bash

# Specify the source and destination project IDs
SOURCE_ORG="tw-rd-de-bill"
DEST_ORG="triple-voyage-362203"
DEST_ACCOUNT="YOUR_DESTINATION_ACCOUNT"
DEST_DIR="/Users/liaopinrui/Downloads/"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the API call to list apps and save the response to a file
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apps" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/apps.json"

echo "Apps list saved to $DEST_DIR/apps.json"

# Extract the app IDs from the JSON file and iterate over them
app_ids=$(jq -r '.app[].appId' "$DEST_DIR/apps.json")

for app_id in $app_ids; do
  # Make the API call for each app ID
  curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apps/$app_id" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/app_$app_id.json"
  
  echo "App info for app ID $app_id saved to $DEST_DIR/app_$app_id.json"
done
