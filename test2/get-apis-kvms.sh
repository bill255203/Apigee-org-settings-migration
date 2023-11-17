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

# Extract the names and keyvaluemap numbers and loop through them for GET requests
for name in $(echo "$response" | jq -r '.proxies[] | .name'); do

  # Construct the URL for the individual curl request to get the ZIP bundle
  url="https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apis/$name/keyvaluemaps"

  # Perform the individual curl request to download the ZIP bundle to the specified directory
  curl -X GET "$url" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${name}_api_keyvaluemaps.json"
  # Extract and sort the keyvaluemap numbers numerically

  keyvaluemaps=($(echo "$response" | jq -r --arg name "$name" '.proxies[] | select(.name == $name).keyvaluemap[]' | sort -n))

  # Loop through the sorted keyvaluemap numbers for each proxy name for GET requests
  for keyvaluemap in "${keyvaluemaps[@]}"; do
    echo "Proxy Name: $name"
    echo "keyvaluemap Number: $keyvaluemap"

    # Construct the URL for the individual curl request to get the ZIP bundle
    url="https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apis/$name/keyvaluemaps/$keyvaluemap"

    # Perform the individual curl request to download the ZIP bundle to the specified directory
    curl -X GET "$url" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${name}_api_${keyvaluemap}_keyvaluemap.json"

    ##################################################################################################################
  done
done
