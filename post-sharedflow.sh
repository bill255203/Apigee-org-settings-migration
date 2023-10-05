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

# Extract sharedflow names from the JSON file and iterate through them
sharedflow_names=($(jq -r '.sharedFlows[].name' "$DEST_DIR/sharedflows.json"))

for sharedflow_name in "${sharedflow_names[@]}"; do
  # Extract revision numbers from the JSON file and iterate through them
  revision_numbers=($(jq -r '.[]' "$DEST_DIR/sharedflow_$sharedflow_name.json"))

  for revision_number in "${revision_numbers[@]}"; do
    # Construct the URL for the individual curl request to deploy the ZIP bundle
    deploy_url="https://apigee.googleapis.com/v1/organizations/$DEST_ORG/sharedflows?name=${sharedflow_name}&action=import"

    # Perform the individual curl request to deploy the ZIP bundle
    curl -X POST "$deploy_url" -H "Authorization: Bearer $DEST_TOKEN" -H "Content-Type: application/octet-stream" --data-binary @"$DEST_DIR/sharedflow_${sharedflow_name}_revision_${revision_number}.zip"
    echo "Details for sharedflow $sharedflow_name revision $revision_number posted"
  done
done

