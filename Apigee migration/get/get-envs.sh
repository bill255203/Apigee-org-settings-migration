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
mkdir -p "$DEST_DIR/get/environment"
mkdir -p "$DEST_DIR/get-err/environment"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the initial API call to list environments
environments_list_file="$DEST_DIR/get/environment/environment_src.json"
error_environments_list_file="$DEST_DIR/get-err/environment/environment_src_error.json"
status_code=$(curl -s -o "$environments_list_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments" -H "Authorization: Bearer $SOURCE_TOKEN")

if [[ "$status_code" -ne 200 ]]; then
  echo "Error retrieving environments list, HTTP status code: $status_code"
  mv "$environments_list_file" "$error_environments_list_file"
else
  echo "Environments list saved to $environments_list_file"
fi

# Parse the environment names from the response
environments=($(jq -r '.[]' "$environments_list_file"))

# Loop through each environment and perform GET requests
for environment in "${environments[@]}"; do
  echo "Processing environment: $environment"

  # Make a GET request to get environment details
  response_file="$DEST_DIR/get/environment/environment_${environment}_src.json"
  error_file="$DEST_DIR/get-err/environment/environment_${environment}_src_error.json"

  status_code=$(curl -s -o "$response_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment" -H "Authorization: Bearer $SOURCE_TOKEN")

  if [[ "$status_code" -ne 200 ]]; then
    echo "Error retrieving environment $environment, HTTP status code: $status_code"
    mv "$response_file" "$error_file"
  else
    echo "Environment details for $environment saved to $response_file"
  fi
done

echo "Environment operations completed."
