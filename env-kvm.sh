#!/bin/bash

# Specify the source and destination project IDs
SOURCE_ORG="tw-rd-de-bill"
DEST_ORG="triple-voyage-362203"
DEST_ACCOUNT="YOUR_DESTINATION_ACCOUNT"
DEST_DIR="/Users/liaopinrui/Downloads/"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Read the environment JSON file into an array
environments=($(jq -r '.[]' "$DEST_DIR/environments.json"))

# Iterate through the environments and make API calls for each one
for environment in "${environments[@]}"; do
  # Make the API call to list key value maps for the current environment
  curl -X GET "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/environments/$environment/keyvaluemaps" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/keyvaluemaps_$environment.json"
  
  echo "Key value maps for environment $environment saved to $DEST_DIR/keyvaluemaps_$environment.json"
done

# Iterate through the environments and make API calls for each one
for environment in "${environments[@]}"; do
  # Make the API call to list key value maps for the current environment
  curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/environments/$environment/keyvaluemaps" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/keyvaluemaps_$environment.json"
  
  echo "Key value maps for environment $environment saved to $DEST_DIR/keyvaluemaps_$environment.json"
done