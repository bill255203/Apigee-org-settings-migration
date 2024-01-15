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

mkdir -p "$DEST_DIR/post/sharedflow/deployment"
mkdir -p "$DEST_DIR/post-err/sharedflow/deployment"

# Parse the sharedflow names
sharedflow_names=($(jq -r '.sharedFlows[].name' "$DEST_DIR/get/sharedflow/sharedflows_src.json"))

for sharedflow_name in "${sharedflow_names[@]}"; do
    transformed_name=$(echo "$sharedflow_name" | tr ' ' '+')

    for sharedflow_name in "${sharedflow_names[@]}"; do
        # Iterate over each deployment object
        deployment_objects=$(jq -c '.deployments[]' "$DEST_DIR/get/sharedflow/deployment/sharedflow_${sharedflow_name}_deployments_src.json")
        while IFS= read -r deployment; do
            env=$(echo "$deployment" | jq -r '.environment')
            name=$(echo "$deployment" | jq -r '.apiProxy')
            revision_number=$(echo "$deployment" | jq -r '.revision')

            # Define file paths for response and error
            deploy_response_file="$DEST_DIR/post/sharedflow/deployment/sharedflow_${name}_revision_${revision_number}_deployment_dst.json"
            deploy_error_file="$DEST_DIR/post-err/sharedflow/deployment/sharedflow_${name}_revision_${revision_number}_deployment_dst_error.json"

            # Deploy the sharedflow
            status_code=$(curl -s -o "$deploy_response_file" -w "%{http_code}" -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/environments/${env}/sharedflows/${name}/revisions/${revision_number}/deployments?override=True" \
                -H "Authorization: Bearer $DEST_TOKEN")

            if [[ $status_code == 2* ]]; then
                echo "Sharedflow $name in environment $env revision $revision_number deployment posted successfully."
            else
                echo "Error deploying sharedflow $name in environment $env revision $revision_number, HTTP status code: $status_code"
                mv "$deploy_response_file" "$deploy_error_file"
            fi
        done <<<"$deployment_objects"
    done
done

echo "Sharedflow revision and deployment operations completed."
