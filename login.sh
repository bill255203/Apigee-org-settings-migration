#!/bin/bash

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

# Authenticate with the destination account
gcloud auth login "$DEST_ACCOUNT"

# Get the OAuth 2.0 access token for the destination project
DEST_TOKEN=$(gcloud auth print-access-token)