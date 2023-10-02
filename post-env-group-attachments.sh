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

# Loop through each environment group and create them in the destination project
for envgroup in "${envgroups[@]}"; do
  for attachment_name in "${attachment_names[@]}"; do
    echo "Processing attachment: $attachment_name"

    # Add your logic here to process each attachment as needed

    echo "Attachment $attachment_name processed."
  done
done

echo "Environment group attachments operations completed."
