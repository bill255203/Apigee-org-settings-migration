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

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the API call to list sharedflows and save the response to a file
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/sharedflows" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/sharedflows.json"

echo "Sharedflows list saved to $DEST_DIR/sharedflows.json"

# Parse the appIds as elements in an array
IFS=$'\n' read -d '' -r -a sharedflow_names < <(jq -r '.sharedFlows[].name' "$DEST_DIR/sharedflows.json")

for sharedflow_name in "${sharedflow_names[@]}"; do
  transformed_name=$(echo "$sharedflow_name" | tr ' ' '+')
  # Make the API call to get details of the current sharedflow
  curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/sharedflows/$transformed_name/revisions" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/sharedflow_$sharedflow_name.json"
  
  echo "Details for sharedflow $sharedflow_name saved to $DEST_DIR/sharedflow_$sharedflow_name.json"

  # Extract revision numbers from the JSON file and iterate through them
  revision_numbers=($(jq -r '.[]' "$DEST_DIR/sharedflow_$sharedflow_name.json"))

  for revision_number in "${revision_numbers[@]}"; do
    # Make the API call to get details of the current sharedflow revision
    curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/sharedflows/$transformed_name/revisions/$revision_number?format=bundle" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/sharedflow_${sharedflow_name}_revision_${revision_number}.zip"
    
    echo "Details for sharedflow $sharedflow_name revision $revision_number saved to $DEST_DIR/sharedflow_${sharedflow_name}_revision_${revision_number}.zip"
  done
done

