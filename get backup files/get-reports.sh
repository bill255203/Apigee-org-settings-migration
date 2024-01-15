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

SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the initial API call to get the JSON response
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/reports" \
  --header "Authorization: Bearer $SOURCE_TOKEN" \
  --header "Accept: application/json" \
  -o "$DEST_DIR/reports.json" \
  --compressed

# Use jq to extract the 'name' values and store them in an array called report_name
report_name=($(jq -r '.qualifier[].name' "$DEST_DIR/reports.json"))

# Loop through the 'report_name'
for report_name in "${report_name[@]}"; do
  echo "report Name: $report_name"
  
  # Make a GET request using the 'report_name' as part of the URL
  curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/reports/$report_name" \
    --header "Authorization: Bearer $SOURCE_TOKEN" \
    -o "$DEST_DIR/report_${report_name}_details.json"

  # Echo a message for each 'report_name'
  echo "Details for report name $report_name have been retrieved."
done


