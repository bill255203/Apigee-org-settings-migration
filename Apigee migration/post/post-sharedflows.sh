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
mkdir -p "$DEST_DIR/post/sharedflow/revision"
mkdir -p "$DEST_DIR/post-err/sharedflow/revision"

# Parse the sharedflow names
sharedflow_names=($(jq -r '.sharedFlows[].name' "$DEST_DIR/get/sharedflow/sharedflows_src.json"))

for sharedflow_name in "${sharedflow_names[@]}"; do
  transformed_name=$(echo "$sharedflow_name" | tr ' ' '+')

  # Extract revision numbers and iterate through them
  revision_numbers=($(jq -r '.[]' "$DEST_DIR/get/sharedflow/revision/sharedflow_${sharedflow_name}_src.json"))

  for revision_number in "${revision_numbers[@]}"; do
    # Define file paths for response and error
    response_file="$DEST_DIR/post/sharedflow/revision/sharedflow_${transformed_name}_revision_${revision_number}_dst.json"
    error_file="$DEST_DIR/post-err/sharedflow/revision/sharedflow_${transformed_name}_revision_${revision_number}_dst_error.json"

    # Deploy the ZIP bundle
    status_code=$(curl -s -o "$response_file" -w "%{http_code}" -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/sharedflows?name=${transformed_name}&action=import" \
      -H "Authorization: Bearer $DEST_TOKEN" \
      -H "Content-Type: application/octet-stream" \
      --data-binary @"$DEST_DIR/get/sharedflow/revision/sharedflow_${sharedflow_name}_revision_${revision_number}_src.zip")

    if [[ $status_code == 2* ]]; then
      echo "Sharedflow $sharedflow_name revision $revision_number posted successfully."
    else
      echo "Error posting sharedflow $sharedflow_name revision $revision_number, HTTP status code: $status_code"
      mv "$response_file" "$error_file"
    fi
  done
done

echo "Sharedflow revision and deployment operations completed."
