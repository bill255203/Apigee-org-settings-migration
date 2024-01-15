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
mkdir -p "$DEST_DIR/get/environment/targetserver"
mkdir -p "$DEST_DIR/get-err/environment/targetserver"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Parse the environment names from the source file
source_file="$DEST_DIR/get/environment/environment_src.json"
if [[ ! -f "$source_file" ]]; then
    echo "Source file not found: $source_file"
    exit 1
fi

environments=($(jq -r '.[]' "$source_file"))

# Loop through each environment and perform GET requests
for environment in "${environments[@]}"; do
    echo "Processing environment: $environment"

    # Define response files
    response_file="$DEST_DIR/get/environment/targetserver/environment_${environment}_targetservers_src.json"
    error_file="$DEST_DIR/get-err/environment/targetserver/environment_${environment}_targetservers_src_error.json"

    # Make a GET request to get environment target servers
    status_code=$(curl -s -o "$response_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/targetservers" -H "Authorization: Bearer $SOURCE_TOKEN")

    if [[ "$status_code" -ne 200 ]]; then
        echo "Error retrieving target servers for environment $environment, HTTP status code: $status_code"
        mv "$response_file" "$error_file"
    else
        echo "Environment target servers src saved to $response_file"

        # Extract the 'targetserver' values from the JSON response
        targetservers=($(jq -r '.[]' "$response_file"))

        # Loop through the 'targetserver' values and perform an HTTP request for each
        for targetserver in "${targetservers[@]}"; do
            echo "Retrieving targetserver: $targetserver"

            # Define targetserver response files
            ts_response_file="$DEST_DIR/get/environment/targetserver/environment_${environment}_targetserver_${targetserver}_src.json"
            ts_error_file="$DEST_DIR/get-err/environment/targetserver/environment_${environment}_targetserver_${targetserver}_src_error.json"

            # Perform the GET request for the targetserver
            ts_status_code=$(curl -s -o "$ts_response_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/targetservers/$targetserver" -H "Authorization: Bearer $SOURCE_TOKEN")

            if [[ "$ts_status_code" -ne 200 ]]; then
                echo "Error retrieving src for targetserver $targetserver, HTTP status code: $ts_status_code"
                mv "$ts_response_file" "$ts_error_file"
            else
                echo "src for targetserver $targetserver has been retrieved."
            fi
        done
    fi
done

echo "Environment operations completed."
