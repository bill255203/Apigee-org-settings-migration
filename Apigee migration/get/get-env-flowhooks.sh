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
mkdir -p "$DEST_DIR/get/environment"
mkdir -p "$DEST_DIR/get-err/environment"
mkdir -p "$DEST_DIR/get/environment/flowhook"
mkdir -p "$DEST_DIR/get-err/environment/flowhook"

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
    response_file="$DEST_DIR/get/environment/flowhook/environment_${environment}_flowhooks_src.json"
    error_file="$DEST_DIR/get-err/environment/flowhook/environment_${environment}_flowhooks_src_error.json"

    # Make a GET request to get environment flowhooks
    status_code=$(curl -s -o "$response_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/flowhooks" -H "Authorization: Bearer $SOURCE_TOKEN")

    if [[ "$status_code" -ne 200 ]]; then
        echo "Error retrieving flowhooks for environment $environment, HTTP status code: $status_code"
        mv "$response_file" "$error_file"
    else
        echo "Environment flowhooks src saved to $response_file"

        # Extract the 'flowhook' values from the JSON response
        flowhooks=($(jq -r '.[]' "$response_file"))

        # Loop through the 'flowhook' values and perform an HTTP request for each 'flowhook'
        for flowhook in "${flowhooks[@]}"; do
            echo "Retrieving flowhook: $flowhook"

            # Define flowhook response files
            flowhook_response_file="$DEST_DIR/get/environment/flowhook/environment_${environment}_flowhook_${flowhook}_src.json"
            flowhook_error_file="$DEST_DIR/get-err/environment/flowhook/environment_${environment}_flowhook_${flowhook}_src_error.json"

            # Perform the GET request for the flowhook
            flowhook_status_code=$(curl -s -o "$flowhook_response_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/flowhooks/$flowhook" -H "Authorization: Bearer $SOURCE_TOKEN")

            if [[ "$flowhook_status_code" -ne 200 ]]; then
                echo "Error retrieving src for flowhook $flowhook, HTTP status code: $flowhook_status_code"
                mv "$flowhook_response_file" "$flowhook_error_file"
            else
                echo "src for flowhook $flowhook has been retrieved."
            fi
        done
    fi
done

echo "Environment operations completed."
