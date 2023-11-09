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
  echo "Retrieving developer information for email: $email"

  # Make the API call to get detailed information for the developer and save it to a file
  curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/developers/$email/subscriptions" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${email}_subs.json"

  echo "Developer information for email $email apps has been retrieved."
  
  # Parse the subs as elements in an array
  ############################################################################################################
  IFS=$'\n' read -d '' -r -a subs < <(jq -r '.app[].sub' "$DEST_DIR/${email}_subs.json")

  # Loop through the subs and make GET requests for each app
  for sub in "${subs[@]}"; do
    # Replace spaces with plus signs in the sub for the API request
    transformed_sub=$(echo "$sub" | tr ' ' '+')
    
    echo "Retrieving app information for sub: $sub (Transformed: $transformed_sub)"

    # Make the API call to get detailed information for the app and save it to a file
    curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/developers/$email/subscriptions/$transformed_sub" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${email}_${sub}_dev_sub_info.json"

    echo "App information for sub $sub has been retrieved."
  done
done
echo "Developer apps information retrieval and import completed."
