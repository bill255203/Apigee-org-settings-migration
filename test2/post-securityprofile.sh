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

# Parse the securityProfile names from the response
securityProfiles=($(cat "$DEST_DIR/securityProfiles.json" | jq -r '.[]'))

# Loop through each securityProfile and perform GET and POST requests
for securityProfile in "${securityProfiles[@]}"; do
  # Create the JSON payload using data from the securityProfile details file
  json_payload=$(cat "$DEST_DIR/${securityProfile}_securityProfile_details.json")

  # Make a POST request to create the securityProfile in the destination project
  create_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/securityProfiles" \
    -H "Authorization: Bearer $DEST_TOKEN" \
    -d "$json_payload" \
    -H "Content-Type: application/json")

  # Save the response for the created securityProfile to a file
  echo "$create_response" > "$DEST_DIR/${securityProfile}_securityProfile_response.json"

  echo "securityProfile $securityProfile created in the destination project."
done

echo "securityProfile operations completed."
