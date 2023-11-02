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
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/datacollectors" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/datacollectors.json"

echo "Apps list saved to $DEST_DIR/datacollectors.json"

# Use jq to extract the 'name' values and store them in an array called datacollector_name
datacollector_names=($(jq -r '.dataCollectors[].name' "$DEST_DIR/datacollectors.json"))

# Loop through each environment and perform GET and POST requests
for datacollector_name in "${datacollector_names[@]}"; do
  # Create the JSON payload using data from the environment details file
  json_payload=$(cat "$DEST_DIR/datacollector_${datacollector_name}_details.json")

  # Make a POST request to create the environment in the destination project
  create_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/datacollectors/${datacollector_name}" \
    -H "Authorization: Bearer $SOURCE_TOKEN" \
    -H "Content-Type: application/json")

  # Save the response for the created environment to a file
  echo "$create_response" > "$DEST_DIR/datacollector_${datacollector_name}_details.json"

  echo "Environment $datacollector_name created in the destination project."
done