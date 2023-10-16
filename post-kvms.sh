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

# Use jq to extract the 'name' values and store them in an array called keyvaluemap_name
keyvaluemap_names=($(jq -r '.keyvaluemaps[].name' "$DEST_DIR/keyvaluemaps.json"))

# Loop through each environment and perform GET and POST requests
for keyvaluemap_name in "${keyvaluemap_names[@]}"; do
  # Create the JSON payload using data from the environment details file
  json_payload=$(cat "$DEST_DIR/keyvaluemap_${keyvaluemap_name}_details.json")

  # Make a POST request to create the environment in the destination project
  create_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/keyvaluemaps/${keyvaluemap_name}" \
    -H "Authorization: Bearer $DEST_TOKEN" \
    -d "$json_payload" \
    -H "Content-Type: application/json")

  # Save the response for the created environment to a file
  echo "$create_response" > "$DEST_DIR/keyvaluemap_${keyvaluemap_name}_response.json"

  echo "Environment $keyvaluemap_name created in the destination project."
done