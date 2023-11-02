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

# Extract the developer emails from the response using jq
emails=($(cat "$DEST_DIR/developers.json" | jq -r '.developer[].email'))

# Loop through the developer emails and retrieve detailed information for each
for email in "${emails[@]}"; do
  # Parse the appIds as elements in an array
  IFS=$'\n' read -d '' -r -a appIds < <(jq -r '.app[].appId' "$DEST_DIR/${email}_dev_apps_info.json")

  # Loop through the appIds and make GET requests for each app
  for appId in "${appIds[@]}"; do
    # Replace spaces with plus signs in the appId for the API request
    transformed_appId=$(echo "$appId" | tr ' ' '+')
    
    echo "Retrieving app information for appId: $appId (Transformed: $transformed_appId)"

    # Make the API call to get detailed information for the app and save it to a file
    curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/developers/$email/apps/$transformed_appId/attributes" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${email}_${appId}_dev_app_attrs.json"
    
    devapp_attrs=($(jq -r '.attribute[].name' "$DEST_DIR/${email}_${appId}_dev_app_attrs.json"))

    for devapp_attr in "${devapp_attrs[@]}"; do
      curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/developers/$email/apps/$transformed_appId/attributes/$devapp_attr" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${email}_${appId}_dev_app_${devapp_attr}_attr_details.json"
    done
  done
done
echo "Developer apps information retrieval and import completed."
