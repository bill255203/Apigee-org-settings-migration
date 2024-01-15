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

# Create directory structure for successful API calls
success_api_dir="$DEST_DIR/get/api"
success_kvm_dir="$success_api_dir/kvm"
mkdir -p "$success_kvm_dir"

# Create directory structure for failed API calls
error_api_dir="$DEST_DIR/get-err/api"
error_kvm_dir="$error_api_dir/kvm"
mkdir -p "$error_kvm_dir"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the initial API call to list apis and save the response to a file
api_list_url="https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apis"
status_code=$(curl -s -o "$success_api_dir/apis_src.json" -w "%{http_code}" -X GET "$api_list_url" -H "Authorization: Bearer $SOURCE_TOKEN")

if [[ "$status_code" -ne 200 ]]; then
    echo "Error retrieving APIs list, HTTP status code: $status_code"
    mv "$success_api_dir/apis_src.json" "$error_api_dir/apis_src_error.json"
else
    echo "APIs list saved to $success_api_dir/apis_src.json"
fi

# Parse the api names from the response
apis=($(jq -r '.proxies[].name' "$success_api_dir/apis_src.json"))

# Loop through each api and perform GET requests
for api in "${apis[@]}"; do
    echo "Processing API: $api"

    # Make a GET request to get API details
    get_kvm_response=$(curl -s -o response.json -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apis/$api/keyvaluemaps" -H "Authorization: Bearer $SOURCE_TOKEN")
    response_body=$(<response.json)
    status_code=$(tail -n1 <<<"$get_kvm_response")

    # Determine file path and suffix based on status code
    if [ "$status_code" -eq 200 ]; then
        file_path="$success_kvm_dir"
        file_suffix="_src"
    else
        file_path="$error_kvm_dir"
        file_suffix="_src_error"
    fi

    # Save the response body to a file with the appropriate suffix
    file_name="api_${api}_kvm${file_suffix}.json"
    echo "$response_body" >"$file_path/$file_name"

    if [ "$status_code" -eq 200 ]; then
        echo "API details saved to $file_path/$file_name"
    else
        echo "Failed to retrieve API details for $api, response saved to $file_path/$file_name"
    fi
done

echo "API operations completed."
# Cleanup the temporary response file
rm -f response.json
