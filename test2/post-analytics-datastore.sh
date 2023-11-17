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

# Parse the datastore names from the response
datastores=($(cat "$DEST_DIR/analytics-datastores.json" | jq -r '.[]'))

# Loop through each datastore and perform GET and POST requests
for datastore in "${datastores[@]}"; do
  # Create the JSON payload using data from the datastore details file
  json_payload=$(cat "$DEST_DIR/${datastore}_analytics_datastore_details.json")

  # Make a POST request to create the datastore in the destination project
  create_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/analytics/datastores" \
    -H "Authorization: Bearer $DEST_TOKEN" \
    -d "$json_payload" \
    -H "Content-Type: application/json")

  # Save the response for the created datastore to a file
  echo "$create_response" > "$DEST_DIR/${datastore}_analytic_datastore_response.json"

  echo "datastore $datastore created in the destination project."
done

echo "datastore operations completed."
