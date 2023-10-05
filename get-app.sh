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

# Make the API call to list apps and save the response to a file
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apps" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/apps.json"

echo "Apps list saved to $DEST_DIR/apps.json"

# Extract the app IDs from the JSON file and iterate over them
app_ids=$(jq -r '.app[].appId' "$DEST_DIR/apps.json")

for app_id in $app_ids; do
  # Make the API call for each app ID
  curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apps/$app_id" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/app_$app_id.json"
  
  echo "App info for app ID $app_id saved to $DEST_DIR/app_$app_id.json"
done