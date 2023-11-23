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

# Parse the app names from the response
apps=($(cat "$DEST_DIR/apps.json" | jq -r '.app[].appId'))

# Loop through each app and perform GET and POST requests
for app in "${apps[@]}"; do
    # Create the JSON payload using data from the app details file
    json_payload=$(cat "$DEST_DIR/${app}_app_details.json")

    # Make a POST request to create the app in the destination project
    create_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/apps" \
        -H "Authorization: Bearer $DEST_TOKEN" \
        -d "$json_payload" \
        -H "Content-Type: application/json")

    # Save the response for the created app to a file
    echo "$create_response" >"$DEST_DIR/${app}_app_response.json"

    echo "app $app created in the destination project."
done

echo "app operations completed."
