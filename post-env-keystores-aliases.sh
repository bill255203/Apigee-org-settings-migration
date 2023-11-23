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

# Parse the environment names from the response
environments=($(cat "$DEST_DIR/envs.json" | jq -r '.[]'))

# Loop through each environment and perform GET and POST requests
for environment in "${environments[@]}"; do
  keystore_names=($(cat "$DEST_DIR/${environment}_env_keystores_details.json" | jq -r '.[]'))

  for keystore in "${keystore_names[@]}"; do
    for aliases_name in "${aliases_names[@]}"; do
        # Create the JSON payload using data from the environment details file
        json_payload=$(cat "$DEST_DIR/${environment}_env_${keystore}_keystore_${aliases_name}_aliases_details.json")

        # Make a POST request to create the environment in the destination project
        create_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/environments/$environment/keystores/$keystore/aliases" \
            -H "Authorization: Bearer $DEST_TOKEN" \
            -d "$json_payload" \
            -H "Content-Type: application/json")
#####################################################################################################################################
        # Save the response for the created environment to a file
        echo "$create_response" > "$DEST_DIR/${environment}_env_${keystore}_keystore_${aliases_name}_aliases_response.json"

        echo "Environment $aliases_name created in the destination project."
    done
  done
done

echo "Environment operations completed."
