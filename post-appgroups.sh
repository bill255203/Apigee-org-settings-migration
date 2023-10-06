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

# Parse the appgroup names from the response using jq
appgroup_names=($(jq -r '.appGroups[].name' "$DEST_DIR/appgroups.json"))

# Loop through each appgroup and perform GET and POST requests
for appgroup_name in "${appgroup_names[@]}"; do
  echo "Processing App Group: $appgroup_name"
  
  # Create the JSON payload using data from the environment details file
  json_payload=$(cat "$DEST_DIR/${appgroup_name}_details.json")
  # Echo the JSON payload before making the POST request
  echo "JSON Payload:"
  echo "$json_payload"
  # Make a POST request to create App Group details in the destination organization
  post_appgroup_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/appgroups" \
  -H "Authorization: Bearer $DEST_TOKEN" \
  -d "$json_payload" \
  -H "Content-Type: application/json")

  # Save the response for the App Group details to a file
  echo "$post_appgroup_response" > "$DEST_DIR/${appgroup_name}_details_response.json"

  echo "App Group details saved to $DEST_DIR/${appgroup_name}_details.json"

done

echo "App Group information retrieval and import completed."
