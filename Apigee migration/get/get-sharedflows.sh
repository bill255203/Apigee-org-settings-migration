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

# Create necessary directories for storing the results
mkdir -p "$DEST_DIR/get/sharedflow/revision"
mkdir -p "$DEST_DIR/get-err/sharedflow/revision"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the API call to list sharedflows
sharedflows_list_file="$DEST_DIR/get/sharedflow/sharedflows_src.json"
error_sharedflows_list_file="$DEST_DIR/get-err/sharedflow/sharedflows_src_error.json"
status_code=$(curl -s -o "$sharedflows_list_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/sharedflows" -H "Authorization: Bearer $SOURCE_TOKEN")

if [[ "$status_code" -ne 200 ]]; then
  echo "Error retrieving sharedflows list, HTTP status code: $status_code"
  mv "$sharedflows_list_file" "$error_sharedflows_list_file"
  exit 1
fi

echo "Sharedflows list saved to $sharedflows_list_file"

# Parse the sharedflow names as elements in an array
sharedflow_names=($(jq -r '.sharedFlows[].name' "$sharedflows_list_file"))

# Loop through each sharedflow name
for sharedflow_name in "${sharedflow_names[@]}"; do
  transformed_name=$(echo "$sharedflow_name" | tr ' ' '+')

  # Get revisions of the sharedflow
  revisions_file="$DEST_DIR/get/sharedflow/revision/sharedflow_${transformed_name}_src.json"
  error_revisions_file="$DEST_DIR/get-err/sharedflow/revision/sharedflow_${transformed_name}_src_error.json"
  status_code=$(curl -s -o "$revisions_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/sharedflows/$transformed_name/revisions" -H "Authorization: Bearer $SOURCE_TOKEN")

  if [[ "$status_code" -ne 200 ]]; then
    echo "Error retrieving revisions for sharedflow $sharedflow_name, HTTP status code: $status_code"
    mv "$revisions_file" "$error_revisions_file"
  else
    echo "Revisions for sharedflow $sharedflow_name saved to $revisions_file"

    # Extract revision numbers
    revision_numbers=($(jq -r '.[]' "$revisions_file"))

    # Loop through each revision number
    for revision_number in "${revision_numbers[@]}"; do
      # Retrieve the sharedflow revision bundle
      bundle_file="$DEST_DIR/get/sharedflow/revision/sharedflow_${transformed_name}_revision_${revision_number}_src.zip"
      error_bundle_file="$DEST_DIR/get-err/sharedflow/revision/sharedflow_${transformed_name}_revision_${revision_number}_src_error.zip"
      status_code=$(curl -s -o "$bundle_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/sharedflows/$transformed_name/revisions/$revision_number?format=bundle" -H "Authorization: Bearer $SOURCE_TOKEN")

      if [[ "$status_code" -ne 200 ]]; then
        echo "Error retrieving sharedflow $sharedflow_name revision $revision_number, HTTP status code: $status_code"
        mv "$bundle_file" "$error_bundle_file"
      else
        echo "Sharedflow $sharedflow_name revision $revision_number bundle saved to $bundle_file"
      fi
    done
  fi
done

echo "Sharedflow operations completed."
