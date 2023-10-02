#!/bin/bash
# Check if jq is installed
if ! [ -x "$(command -v jq)" ]; then
  echo "jq is not installed. Please install jq to continue."
  exit 1
fi

# Load the configuration from the JSON file
CONFIG_FILE="config.json"
if [[ -f "$CONFIG_FILE" ]]; then
  SOURCE_ORG=$(jq -r '.SOURCE_ORG' "$CONFIG_FILE")
  DEST_ORG=$(jq -r '.DEST_ORG' "$CONFIG_FILE")
  DEST_ACCOUNT=$(jq -r '.DEST_ACCOUNT' "$CONFIG_FILE")
  DEST_DIR=$(jq -r '.DEST_DIR' "$CONFIG_FILE")
else
  echo "Config file not found: $CONFIG_FILE"
  exit 1
fi

# Now you can use the variables as needed
echo "SOURCE_ORG: $SOURCE_ORG"
echo "DEST_ORG: $DEST_ORG"
echo "DEST_ACCOUNT: $DEST_ACCOUNT"
echo "DEST_DIR: $DEST_DIR"

source ./get-env-group-attachments.sh

source ./login.sh

source ./post-env-group-attachments.sh