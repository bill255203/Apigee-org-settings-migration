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

SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the initial API call to get the JSON response
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/instances" \
  --header "Authorization: Bearer $SOURCE_TOKEN" \
  --header "Accept: application/json" \
  -o "$DEST_DIR/instances.json" \
  --compressed

# Use jq to extract the 'name' values and store them in an array called instance_name
instance_name=($(jq -r '.instances[].name' "$DEST_DIR/instances.json"))

# Loop through the 'instance_name'
for instance_name in "${instance_name[@]}"; do
  echo "Instance Name: $instance_name"
  
  # Make a GET request using the 'instance_name' as part of the URL
  curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/instances/$instance_name" \
    --header "Authorization: Bearer $SOURCE_TOKEN" \
    -o "$DEST_DIR/instance_${instance_name}_details.json"

  # Echo a message for each 'instance_name'
  echo "Details for instance name $instance_name have been retrieved."
done


