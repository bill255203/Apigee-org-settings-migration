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

# Use jq to extract the 'name' values and store them in an array called instance_name
instance_names=($(jq -r '.instances[].name' "$DEST_DIR/instances.json"))

# Loop through each environment and perform GET and POST requests
for instance_name in "${instance_names[@]}"; do

  # Use jq to extract the 'name' values from the attachments and store them in an array called attachment_names
  attachment_names=($(jq -r '.attachments[].name' "$DEST_DIR/instance_${instance_name}_attachments_details.json"))

  # Loop through the 'attachment_names'
  for attachment_name in "${attachment_names[@]}"; do
    echo "Attachment Name: $attachment_name"
    # Create the JSON payload using data from the environment details file
    json_payload=$(cat "$DEST_DIR/instance_${instance_name}_attachment_${attachment_name}_details.json")

    # Make a POST request to create the environment in the destination project
    create_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/instances/${instance_name}/attachments" \
      -H "Authorization: Bearer $DEST_TOKEN" \
      -d "$json_payload" \
      -H "Content-Type: application/json")

    # Save the response for the created environment to a file
    echo "$create_response" >"$DEST_DIR/instance_${instance_name}_attachment_${attachment_name}_response.json"
  done
done
