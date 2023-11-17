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

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the initial API call to get the JSON response
response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apis?includeRevisions=true" \
  --header "Authorization: Bearer $SOURCE_TOKEN" \
  --header "Accept: application/json" \
  -o "$DEST_DIR/apis.json" \
  --compressed)

# Debugging: Print the API response to the terminal
echo "API Response:"
echo "$response"

# Extract the names and revision numbers and loop through them for GET requests
for name in $(echo "$response" | jq -r '.proxies[] | .name'); do
  # Extract and sort the revision numbers numerically
  revisions=($(echo "$response" | jq -r --arg name "$name" '.proxies[] | select(.name == $name).revision[]' | sort -n))

  # Loop through the sorted revision numbers for each api name for GET requests
  for revision in "${revisions[@]}"; do
    echo "api Name: $name"
    echo "Revision Number: $revision"

    # Construct the URL for the individual curl request to get the ZIP bundle
    url="https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apis/$name/revisions/$revision?format=bundle"

    # Perform the individual curl request to download the ZIP bundle to the specified directory
    curl -X GET "$url" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${name}_api_${revision}_revision.zip"
  done
done
