#!/bin/bash

# Specify the source and destination project IDs
SOURCE_ORG="tw-rd-de-bill"
DEST_ORG="triple-voyage-362203"
DEST_ACCOUNT="YOUR_DESTINATION_ACCOUNT"
DEST_DIR="/Users/liaopinrui/Downloads/"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the initial API call to list developers and save the response to a file
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/developers" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/developers.json"

# Extract the developer emails from the response using jq
emails=($(cat "$DEST_DIR/developers.json" | jq -r '.developer[].email'))

# Authenticate with the destination account
  gcloud auth login "$DEST_ACCOUNT"

  # Get the OAuth 2.0 access token for the destination project
  DEST_TOKEN=$(gcloud auth print-access-token)

# Loop through the developer emails and retrieve detailed information for each
for email in "${emails[@]}"; do
  echo "Retrieving developer information for email: $email"

  # Make the API call to get detailed information for the developer and save it to a file
  curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/developers/$email" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${email}_info.json"

  echo "Developer information for email $email has been retrieved."
  
  # Create or update developers in the destination project using the obtained DEST_TOKEN
  echo "Creating or updating developer for email: $email"
  
  # Load developer information from the JSON file
  developer_info=$(cat "$DEST_DIR/${email}_info.json")
  
  # Make a request to create or update the developer in the destination project
  curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/developers" -H "Authorization: Bearer $DEST_TOKEN" -o "$DEST_DIR/${email}_response.json" -d "$developer_info" -H "Content-Type: application/json"
  
  echo "Developer information for email $email has been created or updated in the destination project."
done

echo "Developer information retrieval and import completed."
