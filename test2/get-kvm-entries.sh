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
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/keyvaluemaps" \
  --header "Authorization: Bearer $SOURCE_TOKEN" \
  --header "Accept: application/json" \
  -o "$DEST_DIR/keyvaluemaps.json" \
  --compressed

# Use jq to extract the 'name' values and store them in an array called keyvaluemap_name
keyvaluemaps=($(jq -r '.keyvaluemaps[].name' "$DEST_DIR/keyvaluemaps.json"))

####################################################################################################

# Loop through the 'keyvaluemap_name'
for keyvaluemap in "${keyvaluemaps[@]}"; do
  echo "keyvaluemap Name: $keyvaluemap"
  
  # Make a GET request using the 'keyvaluemap_name' as part of the URL
  curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/keyvaluemaps/$keyvaluemap/entries" \
    --header "Authorization: Bearer $SOURCE_TOKEN" \
    -o "$DEST_DIR/keyvaluemap_${keyvaluemap}_entries_details.json"

  # Echo a message for each 'keyvaluemap_name'
  echo "Details for keyvaluemap name $keyvaluemap have been retrieved."

  entries=($(jq -r '.keyvaluemaps[].name' "$DEST_DIR/keyvaluemaps_${keyvaluemap}_entries_details.json"))

  for entrie in "${entries[@]}"; do
        # Make a GET request using the 'keyvaluemap_name' as part of the URL
    curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/keyvaluemaps/$keyvaluemap/entries/$entrie" \
        --header "Authorization: Bearer $SOURCE_TOKEN" \
        -o "$DEST_DIR/keyvaluemap_${keyvaluemap}_entries_${entrie}_details.json"

  done
done


