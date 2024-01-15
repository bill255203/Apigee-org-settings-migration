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

# Create necessary directories for POST requests
mkdir -p "$DEST_DIR/post/api"
mkdir -p "$DEST_DIR/post-err/api"

# Get the OAuth 2.0 access token for the destination project
DEST_TOKEN=$(gcloud auth print-access-token)

# Loop through the downloaded ZIP bundles and deploy them with POST requests
api_revision_src_file="$DEST_DIR/get/api/api-revisions_src.json"
if [[ ! -f "$api_revision_src_file" ]]; then
  echo "API revision source file not found: $api_revision_src_file"
  exit 1
fi

for name in $(jq -r '.proxies[] | .name' "$api_revision_src_file"); do
  # Extract and sort the revision numbers numerically
  revisions=($(jq -r --arg name "$name" '.proxies[] | select(.name == $name).revision[]' "$api_revision_src_file" | sort -n))

  for revision in "${revisions[@]}"; do
    echo "Deploying Proxy Name: $name"
    echo "Revision Number: $revision"

    # Construct the URL for the individual curl request to deploy the ZIP bundle
    deploy_url="https://apigee.googleapis.com/v1/organizations/$DEST_ORG/apis?name=${name}&action=import"

    # Perform the individual curl request to deploy the ZIP bundle
    zip_file="$DEST_DIR/get/api/api_${name}_revision_${revision}_src.zip"
    response_file="$DEST_DIR/post/api/api_${name}_revision_${revision}_dst.json"
    error_response_file="$DEST_DIR/post-err/api/api_${name}_revision_${revision}_dst_error.json"

    if [[ ! -f "$zip_file" ]]; then
      echo "ZIP file not found: $zip_file"
      continue
    fi

    status_code=$(curl -s -o "$response_file" -w "%{http_code}" -X POST "$deploy_url" \
      -H "Authorization: Bearer $DEST_TOKEN" \
      -H "Content-Type: application/octet-stream" \
      --data-binary @"$zip_file")
    if [[ $status_code == 2* ]]; then
      echo "API $name revision $revision deployed successfully."
    else
      echo "Error deploying API $name revision $revision, HTTP status code: $status_code"
      mv "$response_file" "$error_response_file"
    fi
  done
done

echo "API deployment operations completed."
