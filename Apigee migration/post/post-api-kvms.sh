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

# Create the necessary directory structure for successful POST responses and errors
post_kvm_dir="$DEST_DIR/post/api/kvm"
post_err_kvm_dir="$DEST_DIR/post-err/api/kvm"
mkdir -p "$post_kvm_dir"
mkdir -p "$post_err_kvm_dir"

# Get the OAuth 2.0 access token for the destination project
DEST_TOKEN=$(gcloud auth print-access-token)

# Parse the api names from the source list
apis=($(jq -r '.proxies[].name' "$DEST_DIR/get/api/apis_src.json"))

# Loop through each api and perform POST requests
for api in "${apis[@]}"; do
  # Ensure the source KVM file exists
  kvm_src_file="$DEST_DIR/get/api/kvm/api_${api}_kvm_src.json"
  if [[ ! -f "$kvm_src_file" ]]; then
    echo "KVM source file not found: $kvm_src_file"
    continue
  fi

  # Extract keyvaluemap names from the source KVM file
  keyvaluemap_names=($(jq -r '.[]' "$kvm_src_file"))

  for keyvaluemap in "${keyvaluemap_names[@]}"; do
    json_payload="{\"name\": \"$keyvaluemap\", \"encrypted\": true}"

    # Make a POST request to create the KVM in the destination project
    response=$(curl -s -o response.json -w "%{http_code}" -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/apis/$api/keyvaluemaps" \
      -H "Authorization: Bearer $DEST_TOKEN" \
      -d "$json_payload" \
      -H "Content-Type: application/json")
    status_code=$(tail -n1 <<<"$response")
    response_body=$(<response.json)

    # Determine file path and suffix based on status code
    if [[ $status_code == 2* ]]; then
      file_path="$post_kvm_dir"
      file_suffix="_dst"
    else
      file_path="$post_err_kvm_dir"
      file_suffix="_dst_error"
    fi

    # Save the response body to a file with the appropriate suffix
    file_name="api_${api}_kvm_${keyvaluemap}${file_suffix}.json"
    echo "$response_body" >"$file_path/$file_name"

    if [[ $status_code == 2* ]]; then
      echo "KVM $keyvaluemap for API $api created in the destination project."
    else
      echo "Error creating KVM $keyvaluemap for API $api in the destination project."
    fi

  done
done

echo "API operations completed."
# Cleanup the temporary response file
rm -f response.json
