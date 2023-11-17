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

# Parse the environment names from the response
environments=($(cat "$DEST_DIR/envs.json" | jq -r '.[]'))

# Loop through each environment and perform GET and POST requests
for environment in "${environments[@]}"; do
  api_names=($(cat "$DEST_DIR/${environment}_env_apis_details.json" | jq -r '.[]'))

  for api in "${api_names[@]}"; do
    # Make a GET request to the api/{ks} endpoint for each api
    api_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/apis/$api/debugsessions" -H "Authorization: Bearer $SOURCE_TOKEN")

    # Save the response for the api to a file
    echo "$api_response" > "$DEST_DIR/${environment}_env_${api}_api_debugsessions_details.json"

    debugsession_names=($(cat "$DEST_DIR/${environment}_env_${api}_api_debugsessions_details.json" | jq -r '.[]'))

    for debugsession_name in "${debugsession_names[@]}"; do
        # Make a GET request to the api/{ks} endpoint for each api
        api_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/apis/$api/debugsessions/$debugsession_name" -H "Authorization: Bearer $SOURCE_TOKEN")

        # Save the response for the api to a file
        echo "$api_response" > "$DEST_DIR/${environment}_env_${api}_api_${debugsession_name}_debugsession_details.json"
    done
  done
done

echo "Environment operations completed."
