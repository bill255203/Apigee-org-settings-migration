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

# Use jq to extract the 'name' values and store them in an array called report_name
report_names=($(jq -r '.qualifier[].name' "$DEST_DIR/reports.json"))

# Loop through each environment and perform GET and POST requests
for report_name in "${report_names[@]}"; do
  # Create the JSON payload using data from the environment details file
  json_payload=$(cat "$DEST_DIR/report_${report_name}_details.json")

  # Make a POST request to create the environment in the destination project
  create_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/reports/${report_name}" \
    -H "Authorization: Bearer $DEST_TOKEN" \
    -d "$json_payload" \
    -H "Content-Type: application/json")

  # Save the response for the created environment to a file
  echo "$create_response" > "$DEST_DIR/report_${report_name}_response.json"

  echo "Environment $report_name created in the destination project."
done