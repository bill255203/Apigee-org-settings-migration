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

# Make the initial API call to list apis and save the response to a file
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apis" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/apis.json"

echo "apis list saved to $DEST_DIR/apis.json"

# Parse the api names from the response
apis=($(cat "$DEST_DIR/apis.json" | jq -r '.[]'))

# Loop through each api and perform GET and POST requests
for api in "${apis[@]}"; do
    echo "Processing api: $api"

    # Make a GET request to get api details
    get_kvm_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apis/$api/keyvaluemaps" -H "Authorization: Bearer $SOURCE_TOKEN")

    # Save the response for the api details to a file
    echo "$get_kvm_response" >"$DEST_DIR/${api}_api_kvm_details.json"

    echo "api details saved to $DEST_DIR/${api}_api_kvm_details.json"
done

echo "api operations completed."
