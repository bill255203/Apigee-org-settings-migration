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
  echo "Processing App Group: $appgroup_name"

  # Make a GET request to get App Group details
  get_appgroup_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/appgroups/$appgroup_name/apps" -H "Authorization: Bearer $SOURCE_TOKEN")

  # Save the response for the App Group details to a file
  echo "$get_appgroup_response" > "$DEST_DIR/${appgroup_name}_apps_details.json"

  echo "App Group details saved to $DEST_DIR/${appgroup_name}_apps_details.json"
  # Parse the app IDs from the app details JSON file using jq
    names=($(jq -r '.appGroupApps[].name' "$DEST_DIR/${appgroup_name}_apps_details.json"))

    # Loop through each app ID and perform GET requests
    for name in "${names[@]}"; do
      echo "Getting details for App ID: $name"

      # Make a GET request to get app details
      get_app_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/appgroups/$appgroup_name/apps/$name" -H "Authorization: Bearer $SOURCE_TOKEN")

      # Save the response for the app details to a file
      echo "$get_app_response" > "$DEST_DIR/${appgroup_name}_${name}_app_details.json"

      echo "App details saved to $DEST_DIR/${appgroup_name}_${name}_app_details.json"
    done
done

echo "Appgroup Apps information retrieval and import completed."
