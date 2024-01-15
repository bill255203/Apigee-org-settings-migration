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

# Create necessary directories for POST dsts
mkdir -p "$DEST_DIR/post/developer"
mkdir -p "$DEST_DIR/post-err/developer"

# Extract the developer emails from the source file using jq
source_file="$DEST_DIR/get/developer/developers_src.json"
if [[ ! -f "$source_file" ]]; then
  echo "Source file not found: $source_file"
  exit 1
fi

emails=($(jq -r '.developer[].email' "$source_file"))

# Loop through the developer emails and retrieve detailed information for each
for email in "${emails[@]}"; do
  echo "Creating or updating developer for email: $email"

  # Load developer information from the JSON file
  developer_info_file="$DEST_DIR/get/developer/developer_${email}_src.json"
  if [[ ! -f "$developer_info_file" ]]; then
    echo "Developer information file not found: $developer_info_file"
    continue
  fi

  developer_info=$(cat "$developer_info_file")

  # Perform the POST request to create or update the developer
  dst_file="$DEST_DIR/post/developer/developer_${email}_dst.json"
  error_file="$DEST_DIR/post-err/developer/developer_${email}_dst_error.json"

  status_code=$(curl -s -o "$dst_file" -w "%{http_code}" -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/developers" \
    -H "Authorization: Bearer $DEST_TOKEN" \
    -d "$developer_info" \
    -H "Content-Type: application/json")
  if [[ $status_code == 2* ]]; then
    echo "Developer information for email $email has been created or updated in the destination project."
  else
    echo "Error creating or updating developer $email, HTTP status code: $status_code"
    mv "$dst_file" "$error_file"
  fi
done

echo "Developer information retrieval and import completed."
