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

# Make the initial API call to list appgroups and save the response to a file
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/appgroups" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/appgroups.json"

echo "App Groups list saved to $DEST_DIR/appgroups.json"

# Parse the appgroup names from the response using jq
appgroup_names=($(jq -r '.appGroups[].name' "$DEST_DIR/appgroups.json"))

# Loop through each appgroup and perform GET and POST requests
for appgroup_name in "${appgroup_names[@]}"; do
  echo "Processing App Group: $appgroup_name"

  # Make a GET request to get App Group details
  get_appgroup_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/appgroups/$appgroup_name" -H "Authorization: Bearer $SOURCE_TOKEN")

  # Save the response for the App Group details to a file
  echo "$get_appgroup_response" > "$DEST_DIR/${appgroup_name}_appgroup_details.json"

  echo "App Group details saved to $DEST_DIR/${appgroup_name}_appgroup_details.json"

done

echo "App Group information retrieval and import completed."
