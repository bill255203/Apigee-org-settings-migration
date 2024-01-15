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

# Extract the developer emails from the response using jq
emails=($(cat "$DEST_DIR/developers.json" | jq -r '.developer[].email'))

# Loop through the developer emails and retrieve detailed information for each
for email in "${emails[@]}"; do
  # Parse the appIds as elements in an array
  IFS=$'\n' read -d '' -r -a appIds < <(jq -r '.app[].appId' "$DEST_DIR/${email}_dev_apps_info.json")
  
  # Check if appIds is empty or null and skip the loop if true
  if [ -z "$appIds" ]; then
    echo "No appIds found for email: $email. Skipping this loop."
    continue
  fi

  # Loop through the appIds and make GET requests for each app
  for appId in "${appIds[@]}"; do
    # Create the JSON payload using data from the environment details file
    devapp_attrs=($(jq -r '.attribute[].name' "$DEST_DIR/${email}_${appId}_dev_app_attrs.json"))

    for devapp_attr in "${devapp_attrs[@]}"; do
        json_payload=$(cat "$DEST_DIR/${email}_${appId}_dev_app_${devapp_attr}_attrs.json")
        echo "$json_payload"
        # Make the API call to get detailed information for the app and save it to a file
        post_dev_app_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/developers/$email/apps/$appId/attributes/$devapp_attr"  \
        -H "Authorization: Bearer $DEST_TOKEN" \
        -d "$json_payload" \
        --header 'Accept: application/json' \
        -H "Content-Type: application/json")
        # Save the response for the app details to a file
        echo "$post_dev_app_response" > "$DEST_DIR/${email}_${appId}_dev_app_${devapp_attr}_attr_response.json"
        echo "App details saved to $DEST_DIR/${email}_${appId}_dev_app_${devapp_attr}_attr_response.json"
  done
  # Clean the appIds array for this email
  unset appIds
done

