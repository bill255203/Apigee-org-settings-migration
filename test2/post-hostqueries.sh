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

# Parse the hostQuerie names from the response
hostQueries=($(cat "$DEST_DIR/hostQueries.json" | jq -r '.[]'))

# Loop through each hostQuerie and perform GET and POST requests
for hostQuerie in "${hostQueries[@]}"; do
  # Create the JSON payload using data from the hostQuerie details file
  json_payload=$(cat "$DEST_DIR/${hostQuerie}_hostQuerie_details.json")

  # Make a POST request to create the hostQuerie in the destination project
  create_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/hostQueries" \
    -H "Authorization: Bearer $DEST_TOKEN" \
    -d "$json_payload" \
    -H "Content-Type: application/json")

  # Save the response for the created hostQuerie to a file
  echo "$create_response" > "$DEST_DIR/${hostQuerie}_hostQuerie_response.json"

  echo "hostQuerie $hostQuerie created in the destination project."
done

echo "hostQuerie operations completed."
