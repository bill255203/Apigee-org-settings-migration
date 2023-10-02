#!/bin/bash

# Check if jq is installed
if ! [ -x "$(command -v jq)" ]; then
  echo "jq is not installed. Please install jq to continue."
  exit 1
fi

# Specify the source and destination organization, account, and directory
SOURCE_ORG="tw-rd-de-bill"
DEST_ORG="triple-voyage-362203"
DEST_ACCOUNT="YOUR_DESTINATION_ACCOUNT"
DEST_DIR="/Users/liaopinrui/Downloads/"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the initial API call to list environment groups and save the response to a file
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/envgroups" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/envgroups.json"

echo "Environment groups list saved to $DEST_DIR/envgroups.json"

# Parse the environment groups from the response
envgroups_json=$(cat "$DEST_DIR/envgroups.json")
envgroups=($(echo "$envgroups_json" | jq -c '.environmentGroups[]'))

# Authenticate with the destination account and get the OAuth token
gcloud auth login "$DEST_ACCOUNT"
DEST_TOKEN=$(gcloud auth print-access-token)

# Loop through each environment group and create them in the destination project
for envgroup in "${envgroups[@]}"; do
  echo "Creating environment group in destination project..."

  # Make a POST request to create the environment group in the destination project
  create_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/envgroups" \
    -H "Authorization: Bearer $DEST_TOKEN" \
    -d "$envgroup" \
    -H "Content-Type: application/json")

  # Save the response for the created environment group to a file
  envgroup_name=$(echo "$envgroup" | jq -r '.name')
  echo "$create_response" > "$DEST_DIR/${envgroup_name}_create_response.json"

  echo "Environment group $envgroup_name created in the destination project."
  # Make a GET request to list attachments associated with the environment group
  attachments_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/envgroups/$envgroup_name/attachments" \
    -H "Authorization: Bearer $DEST_TOKEN")

  # Save the response for attachments to a file
  echo "$attachments_response" > "$DEST_DIR/${envgroup_name}_attachments.json"

  echo "Attachments for environment group $envgroup_name saved."

  # Iterate through the attachments and process them as needed
  attachment_names=($(echo "$attachments_response" | jq -r '.attachments[]'))
  for attachment_name in "${attachment_names[@]}"; do
    echo "Processing attachment: $attachment_name"

    # Add your logic here to process each attachment as needed

    echo "Attachment $attachment_name processed."
  done
done

echo "Environment group operations completed."
