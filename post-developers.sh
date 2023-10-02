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

# Extract the developer emails from the response using jq
emails=($(cat "$DEST_DIR/developers.json" | jq -r '.developer[].email'))

# Loop through the developer emails and retrieve detailed information for each
for email in "${emails[@]}"; do
  echo "Retrieving developer information for email: $email"

  # Make the API call to get detailed information for the developer and save it to a file
  curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/developers/$email" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${email}_info.json"

  echo "Developer information for email $email has been retrieved."
  
  # Create or update developers in the destination project using the obtained DEST_TOKEN
  echo "Creating or updating developer for email: $email"
  
  # Load developer information from the JSON file
  developer_info=$(cat "$DEST_DIR/${email}_info.json")
  
  # Make a request to create or update the developer in the destination project
  curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/developers" -H "Authorization: Bearer $DEST_TOKEN" -o "$DEST_DIR/${email}_response.json" -d "$developer_info" -H "Content-Type: application/json"
  
  echo "Developer information for email $email has been created or updated in the destination project."
done

echo "Developer information retrieval and import completed."
