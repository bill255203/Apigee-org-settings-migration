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

# Create necessary directories for POST responses
mkdir -p "$DEST_DIR/post/developer/app"
mkdir -p "$DEST_DIR/post-err/developer/app"

# Extract the developer emails from the source file using jq
developers_src_file="$DEST_DIR/get/developer/developers_src.json"
if [[ ! -f "$developers_src_file" ]]; then
  echo "Developers source file not found: $developers_src_file"
  exit 1
fi

emails=($(jq -r '.developer[].email' "$developers_src_file"))

# Loop through the developer emails and retrieve detailed information for each
for email in "${emails[@]}"; do
  # Parse the appIds as elements in an array from the source JSON file
  dev_apps_src_file="$DEST_DIR/get/developer/app/developer_${email}_apps_src.json"
  if [[ ! -f "$dev_apps_src_file" ]]; then
    echo "Developer apps source file not found: $dev_apps_src_file"
    continue
  fi

  IFS=$'\n' read -d '' -r -a appIds < <(jq -r '.app[].appId' "$dev_apps_src_file")

  # Loop through the appIds and make POST requests for each app
  for appId in "${appIds[@]}"; do
    json_payload_file="$DEST_DIR/get/developer/app/developer_${email}_app_${appId}_src.json"
    if [[ ! -f "$json_payload_file" ]]; then
      echo "JSON payload file not found: $json_payload_file"
      continue
    fi

    json_payload=$(cat "$json_payload_file")

    response_file="$DEST_DIR/post/developer/app/developer_${email}_app_${appId}_dst.json"
    error_file="$DEST_DIR/post-err/developer/app/developer_${email}_app_${appId}_dst_error.json"

    # Make the POST request to create or update the app
    status_code=$(curl -s -o "$response_file" -w "%{http_code}" -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/developers/$email/apps" \
      -H "Authorization: Bearer $DEST_TOKEN" \
      -d "$json_payload" \
      -H "Content-Type: application/json")
    if [[ $status_code == 2* ]]; then
      echo "App $appId for developer $email has been created or updated in the destination project."
    else
      echo "Error creating or updating app $appId for developer $email, HTTP status code: $status_code"
      mv "$response_file" "$error_file"
    fi
  done
done

echo "Developer apps information processing completed."
