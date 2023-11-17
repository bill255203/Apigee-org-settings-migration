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

# Parse the appgroup names from the response using jq
appgroup_names=($(jq -r '.appGroups[].name' "$DEST_DIR/appgroups.json"))

# Loop through each appgroup and perform GET and POST requests
for appgroup_name in "${appgroup_names[@]}"; do
    apps=($(jq -r '.appGroupApps[].name' "$DEST_DIR/${appgroup_name}_apps_details.json"))

    for app in "${apps[@]}"; do
        # Make a GET request to get app details
        get_keys_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/appgroups/$appgroup_name/apps/$app/keys" -H "Authorization: Bearer $SOURCE_TOKEN")

        # Save the response for the app details to a file
        echo "$get_keys_response" > "$DEST_DIR/${appgroup_name}_${app}_app_keys_details.json"

        echo "App details saved to $DEST_DIR/${appgroup_name}_${app}_app_keys_details.json"
        # Parse the appgroup keys from the response using jq
        keys=($(jq -r '.appGroups[].key' "$DEST_DIR/${appgroup_name}_${app}_app_keys_details.json"))

        # Loop through each appgroup and perform GET and POST requests
        for key in "${keys[@]}"; do

            # Make a GET request to get app details
            get_key_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/appgroups/$appgroup_name/apps/$app/keys/$key" -H "Authorization: Bearer $SOURCE_TOKEN")

            # Save the response for the app details to a file
            echo "$get_key_response" > "$DEST_DIR/${appgroup_name}_${app}_app_${key}_key_details.json"

            echo "App details saved to $DEST_DIR/${appgroup_name}_${app}_app_${key}_key_details.json"
        done
    done
done

echo "Appgroup Apps information retrieval and import completed."
