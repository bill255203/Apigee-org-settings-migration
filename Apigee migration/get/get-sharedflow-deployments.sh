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

mkdir -p "$DEST_DIR/get/sharedflow/deployment"
mkdir -p "$DEST_DIR/get-err/sharedflow/deployment"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the API call to list sharedflows
sharedflows_list_file="$DEST_DIR/get/sharedflow/sharedflows_src.json"
sharedflow_names=($(jq -r '.sharedFlows[].name' "$sharedflows_list_file"))

# Loop through each sharedflow name
for sharedflow_name in "${sharedflow_names[@]}"; do
    transformed_name=$(echo "$sharedflow_name" | tr ' ' '+')
    # Get deployments of the sharedflow
    deployments_file="$DEST_DIR/get/sharedflow/deployment/sharedflow_${transformed_name}_deployments_src.json"
    error_deployments_file="$DEST_DIR/get-err/sharedflow/deployment/sharedflow_${transformed_name}_deployments_src_error.json"
    status_code=$(curl -s -o "$deployments_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/sharedflows/$transformed_name/deployments" -H "Authorization: Bearer $SOURCE_TOKEN")

    if [[ "$status_code" -ne 200 ]]; then
        echo "Error retrieving deployments for sharedflow $sharedflow_name, HTTP status code: $status_code"
        mv "$deployments_file" "$error_deployments_file"
    else
        echo "Deployments for sharedflow $sharedflow_name saved to $deployments_file"
    fi
done

echo "Sharedflow operations completed."
