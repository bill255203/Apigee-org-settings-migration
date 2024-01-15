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

# Create necessary directories for POST requests
mkdir -p "$DEST_DIR/post/api/deployment"
mkdir -p "$DEST_DIR/post-err/api/deployment"

# Get the OAuth 2.0 access token for the destination project
DEST_TOKEN=$(gcloud auth print-access-token)

api_revision_src_file="$DEST_DIR/get/api/api-revisions_src.json"
if [[ ! -f "$api_revision_src_file" ]]; then
    echo "API revision source file not found: $api_revision_src_file"
    exit 1
fi

for proxy_name in $(jq -r '.proxies[] | .name' "$api_revision_src_file"); do
    # revisions=($(jq -r --arg proxy_name "$proxy_name" '.proxies[] | select(.name == $proxy_name).revision[]' "$api_revision_src_file" | sort -n))

    # for revision in "${revisions[@]}"; do
    #     echo "Deploying Proxy Name: $proxy_name"
    #     echo "Revision Number: $revision"

    deployment_file="$DEST_DIR/get/api/deployment/api_${proxy_name}_deployments_src.json"

    # Check if the deployment file is empty or does not exist
    if [ ! -s "$deployment_file" ]; then
        echo "No deployment found for Proxy Name: $proxy_name"
        continue
    fi

    deployment_objects=$(jq -c '.deployments[]' "$deployment_file")
    if [[ -z "$deployment_objects" ]]; then
        echo "No deployments to process for Proxy Name: $proxy_name"
        continue
    fi

    while IFS= read -r deployment; do
        if [[ -z "$deployment" || "$deployment" == "{}" ]]; then
            echo "Skipping empty deployment for Proxy Name: $proxy_name, Revision: $revision"
            continue
        fi

        env=$(echo "$deployment" | jq -r '.environment')
        deployed_name=$(echo "$deployment" | jq -r '.apiProxy')
        revision_number=$(echo "$deployment" | jq -r '.revision')

        deploy_response_file="$DEST_DIR/post/api/deployment/api_${deployed_name}_revision_${revision_number}_deployment_dst.json"
        deploy_error_file="$DEST_DIR/post-err/api/deployment/api_${deployed_name}_revision_${revision_number}_deployment_dst_error.json"

        status_code=$(curl -s -o "$deploy_response_file" -w "%{http_code}" -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/environments/${env}/apis/${deployed_name}/revisions/${revision_number}/deployments?override=True" \
            -H "Authorization: Bearer $DEST_TOKEN")

        if [[ $status_code == 2* ]]; then
            echo "API Proxy $deployed_name in environment $env revision $revision_number deployment posted successfully."
        else
            echo "Error deploying API Proxy $deployed_name in environment $env revision $revision_number, HTTP status code: $status_code"
            mv "$deploy_response_file" "$deploy_error_file"
        fi
    done <<<"$deployment_objects"
    # done
done

echo "API deployment operations completed."
