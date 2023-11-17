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

# Make the initial API call to list analytics/datastores and save the response to a file
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/analytics/datastores" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/analytics-datastores.json"

echo "analytics/datastores list saved to $DEST_DIR/analytics-datastores.json"

# Parse the environment names from the response
datastores=($(cat "$DEST_DIR/analytics-datastores.json" | jq -r '.[]'))

# Loop through each environment and perform GET and POST requests
for datastore in "${datastores[@]}"; do
  echo "Processing environment: $datastore"

  # Make a GET request to get environment details
  get_datastore_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/analytics/datastores/$datastore" -H "Authorization: Bearer $SOURCE_TOKEN")

  # Save the response for the environment details to a file
  echo "$get_datastore_response" > "$DEST_DIR/${datastore}_analytics_datastore_details.json"

  echo "analytics_datastore details saved to $DEST_DIR/${datastore}_analytics_datastore_details.json"
done

echo "Analytics_datastore operations completed."
