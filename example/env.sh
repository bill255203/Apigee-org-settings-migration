#!/bin/bash

# Specify the source and destination organization, account, and directory
SOURCE_ORG="tw-rd-de-bill"
DEST_ORG="triple-voyage-362203"
DEST_ACCOUNT="YOUR_DESTINATION_ACCOUNT"
DEST_DIR="/Users/liaopinrui/Downloads/"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the initial API call to list environments and save the response to a file
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/environments.json"

echo "Environments list saved to $DEST_DIR/environments.json"

# Parse the environment names from the response
environments=($(cat "$DEST_DIR/environments.json" | jq -r '.[]'))

# Authenticate with the destination account and get the OAuth token
gcloud auth login "$DEST_ACCOUNT"
DEST_TOKEN=$(gcloud auth print-access-token)

# Loop through each environment and perform GET and POST requests
for environment in "${environments[@]}"; do
  echo "Processing environment: $environment"

  # Make a GET request to get environment details
  get_env_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment" -H "Authorization: Bearer $SOURCE_TOKEN")

  # Save the response for the environment details to a file
  echo "$get_env_response" > "$DEST_DIR/${environment}_details.json"

  echo "Environment details saved to $DEST_DIR/${environment}_details.json"

  # Prepare the JSON payload for creating the environment in the destination project
  json_payload='{
    "name": "'"$environment"'"
  }'

  # Make a POST request to create the environment in the destination project
  create_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/environments" \
    -H "Authorization: Bearer $DEST_TOKEN" \
    -d "$json_payload" \
    -H "Content-Type: application/json")

  # Save the response for the created environment to a file
  echo "$create_response" > "$DEST_DIR/${environment}_create_response.json"

  echo "Environment $environment created in the destination project."
done

echo "Environment operations completed."
