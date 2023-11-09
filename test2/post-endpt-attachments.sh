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

# Parse the endpointAttachment names from the response
endpointAttachments=($(cat "$DEST_DIR/endpts.json" | jq -r '.[]'))

# Loop through each endpointAttachment and perform GET and POST requests
for endpointAttachment in "${endpointAttachments[@]}"; do
  # Create the JSON payload using data from the endpointAttachment details file
  json_payload=$(cat "$DEST_DIR/${endpointAttachment}_endpt_details.json")

  # Make a POST request to create the endpointAttachment in the destination project
  create_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/endpointAttachments" \
    -H "Authorization: Bearer $DEST_TOKEN" \
    -d "$json_payload" \
    -H "Content-Type: application/json")

  # Save the response for the created endpointAttachment to a file
  echo "$create_response" > "$DEST_DIR/${endpointAttachment}_endpt_response.json"

  echo "endpointAttachment $endpointAttachment created in the destination project."
done

echo "endpointAttachment operations completed."
