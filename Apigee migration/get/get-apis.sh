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

# Ensure the destination directories exist for successful and error responses
mkdir -p "$DEST_DIR/get/api"
mkdir -p "$DEST_DIR/get-err/api"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the initial API call to get the JSON dst
status_code=$(curl -s -o "$DEST_DIR/get/api/api-revisions_src.json" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apis?includeRevisions=true" \
  --header "Authorization: Bearer $SOURCE_TOKEN" \
  --header "Accept: application/json" \
  --compressed)

if [[ "$status_code" -ne 200 ]]; then
  echo "Error retrieving API revisions, HTTP status code: $status_code"
  mv "$DEST_DIR/get/api/api-revisions_src.json" "$DEST_DIR/get-err/api/api-revisions_src_error.json"
else
  echo "API revisions dst saved to $DEST_DIR/get/api/api-revisions_src.json"
fi

# Loop through each api name and revision number for GET requests
for name in $(jq -r '.proxies[] | .name' "$DEST_DIR/get/api/api-revisions_src.json"); do
  revisions=($(jq -r --arg name "$name" '.proxies[] | select(.name == $name).revision[]' "$DEST_DIR/get/api/api-revisions_src.json" | sort -n))

  for revision in "${revisions[@]}"; do
    echo "API Name: $name"
    echo "Revision Number: $revision"

    # Construct the URL for the individual curl request to get the ZIP bundle
    url="https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apis/$name/revisions/$revision?format=bundle"
    zip_file_path="$DEST_DIR/get/api/api_${name}_revision_${revision}_src.zip"

    # Perform the individual curl request to download the ZIP bundle to the specified directory
    status_code=$(curl -s -o "$zip_file_path" -w "%{http_code}" -X GET "$url" -H "Authorization: Bearer $SOURCE_TOKEN")

    if [[ "$status_code" -ne 200 ]]; then
      echo "Error downloading API $name revision $revision, HTTP status code: $status_code"
      mv "$zip_file_path" "$DEST_DIR/get-err/api/api_${name}_revision_${revision}_src_error.zip"
    else
      echo "API $name revision $revision downloaded to $zip_file_path"
    fi
  done
done

echo "API operations completed."
