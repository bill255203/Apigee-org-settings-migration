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

# Create necessary directories for storing POST request results
mkdir -p "$DEST_DIR/post/environment/kvm"
mkdir -p "$DEST_DIR/post-err/environment/kvm"

# Parse the environment names from the source file
environments=($(jq -r '.[]' "$DEST_DIR/get/environment/environment_src.json"))

# Loop through each environment and perform POST requests
for environment in "${environments[@]}"; do
  keyvaluemap_names=($(jq -r '.[]' "$DEST_DIR/get/environment/kvm/environment_${environment}_kvms_src.json"))

  for keyvaluemap in "${keyvaluemap_names[@]}"; do
    json_payload="{\"name\": \"$keyvaluemap\", \"encrypted\": true}"

    # Define file paths for response and error
    response_file="$DEST_DIR/post/environment/kvm/environment_${environment}_kvm_${keyvaluemap}_dst.json"
    error_file="$DEST_DIR/post-err/environment/kvm/environment_${environment}_kvm_${keyvaluemap}_dst_error.json"

    # Make the POST request to create the keyvaluemap
    status_code=$(curl -s -o "$response_file" -w "%{http_code}" -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/environments/$environment/keyvaluemaps" \
      -H "Authorization: Bearer $DEST_TOKEN" \
      -d "$json_payload" \
      -H "Content-Type: application/json")

    if [[ $status_code == 2* ]]; then
      echo "Keyvaluemap $keyvaluemap created in environment $environment."
    else
      echo "Error creating keyvaluemap $keyvaluemap in environment $environment, HTTP status code: $status_code"
      mv "$response_file" "$error_file"
    fi
  done
done

echo "Environment keyvaluemap operations completed."
