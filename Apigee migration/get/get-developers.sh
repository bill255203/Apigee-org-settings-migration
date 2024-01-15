#!/bin/bash

# Import the JSON configuration
CONFIG_FILE="config.json"
if [[ -f "$CONFIG_FILE" ]]; then
  source <(jq -r 'to_entries | .[] | "export \(.key)=\(.value)"' "$CONFIG_FILE")
else
  echo "Config file not found: $CONFIG_FILE"
  exit 1
fi

# Now you can use the parameters in this script
echo "SOURCE_ORG in env.sh: $SOURCE_ORG"
echo "DEST_ORG in env.sh: $DEST_ORG"
echo "DEST_ACCOUNT in env.sh: $DEST_ACCOUNT"
echo "DEST_DIR in env.sh: $DEST_DIR"

# Create necessary directories for GET requests
mkdir -p "$DEST_DIR/get/developer"
mkdir -p "$DEST_DIR/get-err/developer"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the initial API call to list developers
developers_list_file="$DEST_DIR/get/developer/developers_src.json"
curl -s -o "$developers_list_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/developers" -H "Authorization: Bearer $SOURCE_TOKEN"

# Extract the developer emails from the response using jq
emails=($(jq -r '.developer[].email' "$developers_list_file"))

# Loop through the developer emails and retrieve detailed information for each
for email in "${emails[@]}"; do
  echo "Retrieving developer information for email: $email"

  # Make the API call to get detailed information for the developer
  response_file="$DEST_DIR/get/developer/developer_${email}_src.json"
  error_file="$DEST_DIR/get-err/developer/developer_${email}_src_error.json"
  status_code=$(curl -s -o "$response_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/developers/$email" -H "Authorization: Bearer $SOURCE_TOKEN")

  if [[ "$status_code" -ne 200 ]]; then
    echo "Error retrieving information for developer $email, HTTP status code: $status_code"
    mv "$response_file" "$error_file"
  else
    echo "Developer information for email $email has been retrieved."
  fi
done
