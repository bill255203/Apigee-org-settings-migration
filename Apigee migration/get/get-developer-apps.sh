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
mkdir -p "$DEST_DIR/get/developer/app"
mkdir -p "$DEST_DIR/get-err/developer/app"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Extract the developer emails from the source file using jq
developers_src_file="$DEST_DIR/get/developer/developers_src.json"
if [[ ! -f "$developers_src_file" ]]; then
  echo "Developers src file not found: $developers_src_file"
  exit 1
fi

emails=($(jq -r '.developer[].email' "$developers_src_file"))

# Loop through the developer emails and retrieve detailed information for each
for email in "${emails[@]}"; do
  echo "Retrieving developer information for email: $email"

  # Make the API call to get detailed information for the developer and save it to a file
  response_file="$DEST_DIR/get/developer/app/developer_${email}_apps_src.json"
  error_file="$DEST_DIR/get-err/developer/app/developer_${email}_apps_src_error.json"

  status_code=$(curl -s -o "$response_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/developers/$email/apps" -H "Authorization: Bearer $SOURCE_TOKEN")

  if [[ "$status_code" -ne 200 ]]; then
    echo "Error retrieving developer apps for $email, HTTP status code: $status_code"
    mv "$response_file" "$error_file"
  else
    echo "Developer apps information for email $email has been retrieved."

    # Parse the appIds as elements in an array
    IFS=$'\n' read -d '' -r -a appIds < <(jq -r '.app[].appId' "$response_file")

    # Loop through the appIds and make GET requests for each app
    for appId in "${appIds[@]}"; do
      transformed_appId=$(echo "$appId" | tr ' ' '+')
      echo "Retrieving app information for appId: $appId (Transformed: $transformed_appId)"

      app_response_file="$DEST_DIR/get/developer/app/developer_${email}_app_${appId}_src.json"
      app_error_file="$DEST_DIR/get-err/developer/app/developer_${email}_app_${appId}_src_error.json"

      app_status_code=$(curl -s -o "$app_response_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/developers/$email/apps/$transformed_appId" -H "Authorization: Bearer $SOURCE_TOKEN")

      if [[ "$app_status_code" -ne 200 ]]; then
        echo "Error retrieving app $appId for developer $email, HTTP status code: $app_status_code"
        mv "$app_response_file" "$app_error_file"
      else
        echo "App information for appId $appId has been retrieved."
      fi
    done
  fi
done

echo "Developer apps information retrieval and import completed."
