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

# Create necessary directories for storing the results
mkdir -p "$DEST_DIR/get/kvm"
mkdir -p "$DEST_DIR/get-err/kvm"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Define file paths for the successful and error responses
success_file="$DEST_DIR/get/kvm/keyvaluemaps_src.json"
error_file="$DEST_DIR/get-err/kvm/keyvaluemaps_src_error.json"

# Make the initial API call
status_code=$(curl -s -o "$success_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/keyvaluemaps" \
    --header "Authorization: Bearer $SOURCE_TOKEN" \
    --header "Accept: application/json" \
    --compressed)

# Check response status code
if [[ "$status_code" -ne 200 ]]; then
    echo "Error retrieving keyvaluemaps, HTTP status code: $status_code"
    mv "$success_file" "$error_file"
else
    echo "Keyvaluemaps list saved to $success_file"
    keyvaluemaps=($(jq -r '.keyvaluemaps[].name' "$success_file"))
fi

echo "Keyvaluemap operations completed."
