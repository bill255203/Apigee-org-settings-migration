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
  keystore_names=($(cat "$DEST_DIR/${environment}_envs.json" | jq -r '.[]'))

  for keystore in "${keystore_names[@]}"; do
    # Make a GET request to the keystore/{ks} endpoint for each keystore
    keystore_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/keystores/$keystore/aliases" -H "Authorization: Bearer $SOURCE_TOKEN")

    # Save the response for the keystore to a file
    echo "$keystore_response" > "$DEST_DIR/${environment}_env_${keystore}_keystore_aliases_details.json"

    aliases_names=($(cat "$DEST_DIR/${environment}_env_${keystore}_keystore_aliases_details.json" | jq -r '.[]'))

    for aliases_name in "${aliases_names[@]}"; do
        # Make a GET request to the keystore/{ks} endpoint for each keystore
        keystore_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/keystores/$keystore/aliases/$aliases_name" -H "Authorization: Bearer $SOURCE_TOKEN")

        # Save the response for the keystore to a file
        echo "$keystore_response" > "$DEST_DIR/${environment}_env_${keystore}_keystore_${aliases_name}_aliases_details.json"
    done
  done
done

echo "Environment operations completed."
