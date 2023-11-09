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

# Make the initial API call to list securityProfiles and save the response to a file
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/securityProfiles" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/securityProfiles.json"

echo "securityProfiles list saved to $DEST_DIR/securityProfiles.json"

# Parse the securityProfile names from the response
securityProfiles=($(cat "$DEST_DIR/securityProfiles.json" | jq -r '.[]'))

# Loop through each securityProfile and perform GET and POST requests
for securityProfile in "${securityProfiles[@]}"; do
  echo "Processing securityProfile: $securityProfile"

  # Make a GET request to get securityProfile details
  get_securityProfile_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/securityProfiles/$securityProfile" -H "Authorization: Bearer $SOURCE_TOKEN")

  # Save the response for the securityProfile details to a file
  echo "$get_securityProfile_response" > "$DEST_DIR/${securityProfile}_securityProfile_details.json"

  echo "securityProfile details saved to $DEST_DIR/${securityProfile}_securityProfile_details.json"
done

echo "securityProfile operations completed."
