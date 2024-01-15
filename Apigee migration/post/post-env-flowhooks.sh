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

# Create necessary directories for storing PUT request results
mkdir -p "$DEST_DIR/post/environment/flowhook"
mkdir -p "$DEST_DIR/post-err/environment/flowhook"

# Parse the environment names from the source file
environments=($(jq -r '.[]' "$DEST_DIR/get/environment/environment_src.json"))

# Loop through each environment and perform PUT requests
for environment in "${environments[@]}"; do
    flowhook_names=($(jq -r '.[]' "$DEST_DIR/get/environment/flowhook/environment_${environment}_flowhooks_src.json"))

    for flowhook in "${flowhook_names[@]}"; do
        json_payload_file="$DEST_DIR/get/environment/flowhook/environment_${environment}_flowhook_${flowhook}_src.json"
        if [[ ! -f "$json_payload_file" ]]; then
            echo "JSON payload file not found: $json_payload_file"
            continue
        fi

        json_payload=$(cat "$json_payload_file")

        # Define file paths for response and error
        response_file="$DEST_DIR/post/environment/flowhook/environment_${environment}_flowhook_${flowhook}_dst.json"
        error_file="$DEST_DIR/post-err/environment/flowhook/environment_${environment}_flowhook_${flowhook}_dst_error.json"

        # Make the PUT request to create the flowhook
        status_code=$(curl -s -o "$response_file" -w "%{http_code}" -X PUT "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/environments/$environment/flowhooks/$flowhook" \
            -H "Authorization: Bearer $DEST_TOKEN" \
            -d "$json_payload" \
            -H "Content-Type: application/json")
        if [[ $status_code == 2* ]]; then
            echo "Flowhook $flowhook created in environment $environment."
        else
            echo "Error creating flowhook $flowhook in environment $environment, HTTP status code: $status_code"
            mv "$response_file" "$error_file"
        fi
    done
done

echo "Environment flowhook operations completed."
