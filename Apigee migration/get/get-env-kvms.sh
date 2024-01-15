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

# Create necessary directories for GET requests
mkdir -p "$DEST_DIR/get/environment/kvm"
mkdir -p "$DEST_DIR/get-err/environment/kvm"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Parse the environment names from the source file
source_file="$DEST_DIR/get/environment/environment_src.json"
if [[ ! -f "$source_file" ]]; then
  echo "Source file not found: $source_file"
  exit 1
fi

environments=($(jq -r '.[]' "$source_file"))

# Loop through each environment and perform GET requests
for environment in "${environments[@]}"; do
  echo "Processing environment: $environment"

  # Define response and error files
  response_file="$DEST_DIR/get/environment/kvm/environment_${environment}_kvms_src.json"
  error_file="$DEST_DIR/get-err/environment/kvm/environment_${environment}_kvms_src_error.json"

  # Make a GET request to get environment KVMs
  status_code=$(curl -s -o "$response_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/keyvaluemaps" -H "Authorization: Bearer $SOURCE_TOKEN")

  if [[ "$status_code" -ne 200 ]]; then
    echo "Error retrieving KVMs for environment $environment, HTTP status code: $status_code"
    mv "$response_file" "$error_file"
  else
    echo "Environment KVMs src saved to $response_file"
  fi
done

echo "Environment operations completed."
