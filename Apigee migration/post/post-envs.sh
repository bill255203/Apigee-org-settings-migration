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

# Create necessary directories for POST requests
mkdir -p "$DEST_DIR/post/environment"
mkdir -p "$DEST_DIR/post-err/environment"

# Parse the environment names from the source file
source_file="$DEST_DIR/get/environment/environment_src.json"
if [[ ! -f "$source_file" ]]; then
  echo "Source file not found: $source_file"
  exit 1
fi

environments=($(jq -r '.[]' "$source_file"))

# Loop through each environment and perform POST requests
for environment in "${environments[@]}"; do
  # Load JSON payload from the source file
  json_payload_file="$DEST_DIR/get/environment/environment_${environment}_src.json"
  if [[ ! -f "$json_payload_file" ]]; then
    echo "JSON payload file not found: $json_payload_file"
    continue
  fi

  json_payload=$(cat "$json_payload_file")

  # Determine the file paths for response and error
  response_file="$DEST_DIR/post/environment/environment_${environment}_dst.json"
  error_file="$DEST_DIR/post-err/environment/environment_${environment}_dst_error.json"

  # Make the POST request to create the environment
  status_code=$(curl -s -o "$response_file" -w "%{http_code}" -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/environments" \
    -H "Authorization: Bearer $DEST_TOKEN" \
    -d "$json_payload" \
    -H "Content-Type: application/json")
  if [[ $status_code == 2* ]]; then
    echo "Environment $environment created in the destination project."
  else
    echo "Error creating environment $environment, HTTP status code: $status_code"
    mv "$response_file" "$error_file"
  fi
done

echo "Environment operations completed."
