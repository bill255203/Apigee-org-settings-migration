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

# Parse the environment groups from the response
envgroups_json=$(cat "$DEST_DIR/envgroups.json")
envgroups=($(echo "$envgroups_json" | jq -c '.environmentGroups[]'))

# Loop through each environment group and create them in the destination project
for envgroup in "${envgroups[@]}"; do
# Extract the environment group name
  envgroup_name=$(echo "$envgroup" | jq -r '.name')
  # Make a GET request to list attachments associated with the environment group
  attachments_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/envgroups/$envgroup_name/attachments" \
    -H "Authorization: Bearer $SOURCE_TOKEN")

  # Save the response for attachments to a file
  echo "$attachments_response" > "$DEST_DIR/${envgroup_name}_envgroup_attachments.json"

  echo "Attachments for environment group $envgroup_name saved."

  # Iterate through the attachments and process them as needed
  attachment_names=($(echo "$attachments_response" | jq -r '.attachments[]'))
  done
done

echo "Environment group operations completed."
