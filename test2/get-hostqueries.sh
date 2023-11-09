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

# Make the initial API call to list hostQueries and save the response to a file
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/hostQueries" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/hostQueries.json"

echo "hostQueries list saved to $DEST_DIR/hostQueries.json"

# Parse the hostQuerie names from the response
hostQueries=($(cat "$DEST_DIR/hostQueries.json" | jq -r '.[]'))

# Loop through each hostQuerie and perform GET and POST requests
for hostQuerie in "${hostQueries[@]}"; do
  echo "Processing hostQuerie: $hostQuerie"

  # Make a GET request to get hostQuerie details
  get_hostQuerie_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/hostQueries/$hostQuerie" -H "Authorization: Bearer $SOURCE_TOKEN")

  # Save the response for the hostQuerie details to a file
  echo "$get_hostQuerie_response" > "$DEST_DIR/${hostQuerie}_hostQuerie_details.json"

  echo "hostQuerie details saved to $DEST_DIR/${hostQuerie}_hostQuerie_details.json"
done

echo "hostQuerie operations completed."
