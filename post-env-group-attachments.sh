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

# Parse the environment groups from the response
envgroups_json=$(cat "$DEST_DIR/envgroups.json")
envgroups=($(echo "$envgroups_json" | jq -c '.environmentGroups[]'))
# Print the envgroups
echo "Environment Groups:"
for envgroup in "${envgroups[@]}"; do
  echo "$envgroup"
done

# Loop through each environment group
for envgroup in "${envgroups[@]}"; do
  # Extract the environment group name
  envgroup_name=$(echo "$envgroup" | jq -r '.name')

  # Read the attachments file for the current environment group
  attachments_file="$DEST_DIR${envgroup_name}_envgroup_attachments.json"
  
  # Check if the attachments file exists
  if [[ -f "$attachments_file" ]]; then
    # Iterate through the environmentGroupAttachments array
    while read -r attachment; do
      # Print the attachment data
      echo "Attachment Data:"
      echo "$attachment"

      # Construct the URL for the POST request
      post_url="https://apigee.googleapis.com/v1/organizations/$DEST_ORG/envgroups/$envgroup_name/attachments"

      # Make a POST request for each attachment
      attachment_response=$(curl -X POST "$post_url" \
        -H "Authorization: Bearer $SOURCE_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$attachment")

      # Save the response for the attachment to a file if needed
      echo "$attachment_response" > "$DEST_DIR/${envgroup_name}_${attachment_name}_envgroup_attachments_response.json"

      echo "Attachment for environment group $envgroup_name created."
    done < <(jq -c '.environmentGroupAttachments[]' "$attachments_file")
  else
    echo "Attachments file not found: $attachments_file"
  fi
done