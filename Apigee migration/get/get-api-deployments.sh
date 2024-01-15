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

mkdir -p "$DEST_DIR/get/api/deployment"
mkdir -p "$DEST_DIR/get-err/api/deployment"
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Loop through each api name and revision number for GET requests
for name in $(jq -r '.proxies[] | .name' "$DEST_DIR/get/api/api-revisions_src.json"); do
    # revisions=($(jq -r --arg name "$name" '.proxies[] | select(.name == $name).revision[]' "$DEST_DIR/get/api/api-revisions_src.json" | sort -n))

    # for revision in "${revisions[@]}"; do
    #     echo "API Name: $name"
    #     echo "Revision Number: $revision"

    deployments_file="$DEST_DIR/get/api/deployment/api_${name}_deployments_src.json"
    error_deployments_file="$DEST_DIR/get-err/api/deployment/api_${name}_deployments_src_error.json"
    status_code=$(curl -s -o "$deployments_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apis/$name/deployments" -H "Authorization: Bearer $SOURCE_TOKEN")

    if [[ "$status_code" -ne 200 ]]; then
        echo "Error retrieving deployments for api $name, HTTP status code: $status_code"
        mv "$deployments_file" "$error_deployments_file"
    else
        echo "Deployments for api $name saved to $deployments_file"
    fi
    # done
done

echo "API operations completed."
