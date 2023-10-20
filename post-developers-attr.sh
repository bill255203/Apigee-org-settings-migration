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
  # Extract the 'name' values from the JSON response
  names=($(cat "$DEST_DIR/${email}_developer_attr_details.json" | jq -r '.attribute[].name'))

  # Now you can loop through the 'name' values and perform an HTTP request for each 'name'
  for name in "${names[@]}"; do
    echo "Name: $name"

    # Perform the HTTP request using the 'name' value
    curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/developers/$email/attributes/$name" -H "Authorization: Bearer $DEST_TOKEN" -o "$DEST_DIR/${email}_developer_${name}_attr_response.json" -H "Content-Type: application/json"

    echo "Details for name $name have been posted."
  done

  echo "all details have been posted."
done