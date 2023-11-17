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

# Parse the environment names from the response
environments=($(cat "$DEST_DIR/envs.json" | jq -r '.[]'))

# Loop through each environment and perform GET and POST requests
for environment in "${environments[@]}"; do

  keyvaluemaps=($(cat "$DEST_DIR/${environment}_keyvaluemaps_details.json" | jq -r '.attribute[].keyvaluemap'))

  # Now you can loop through the 'keyvaluemap' values and perform an HTTP request for each 'keyvaluemap'
  for keyvaluemap in "${keyvaluemaps[@]}"; do
    # Perform the HTTP request using the 'keyvaluemap' value
    curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/keyvaluemaps/$keyvaluemap/entries" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${environment}_env_${keyvaluemap}_kvm_entries_details.json"

    echo "Details for keyvaluemap entries $keyvaluemap have been retrieved."

    entries=($(cat "$DEST_DIR/${environment}_env_${keyvaluemap}_kvm_entries_details.json" | jq -r '.attribute[].entrie'))

    # Now you can loop through the 'entrie' values and perform an HTTP request for each 'entrie'
    for entrie in "${entries[@]}"; do
      curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/keyvaluemaps/$keyvaluemap/entries/$entrie" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${environment}_env_${entrie}_kvm_${entrie}_entrie_details.json"

      echo "Details for entrie entries $entrie have been retrieved."
    done
  done
done

echo "Entries operations completed."
