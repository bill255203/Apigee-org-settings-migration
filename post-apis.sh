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

# Loop through the downloaded ZIP bundles and deploy them with POST requests
for name in $(echo "$response" | jq -r '.proxies[] | .name'); do
  # Extract and sort the revision numbers numerically
  revisions=($(echo "$response" | jq -r --arg name "$name" '.proxies[] | select(.name == $name).revision[]' | sort -n))

  # Loop through the sorted revision numbers for each proxy name for POST requests
  for revision in "${revisions[@]}"; do
    echo "Deploying Proxy Name: $name"
    echo "Revision Number: $revision"

    # Construct the URL for the individual curl request to deploy the ZIP bundle
    deploy_url="https://apigee.googleapis.com/v1/organizations/$DEST_ORG/apis?name=${name}&action=import"

    # Perform the individual curl request to deploy the ZIP bundle
    curl -X POST "$deploy_url" -H "Authorization: Bearer $DEST_TOKEN" -H "Content-Type: application/octet-stream" --data-binary @"$DEST_DIR/${name}_api_${revision}_revision.zip" -o "$DEST_DIR/${name}_api_${revision}_revision_response.json"
  done
done
