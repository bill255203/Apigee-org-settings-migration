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

# Parse the api names from the response
apis=($(cat "$DEST_DIR/apis.json" | jq -r '.proxies[].name'))

# Loop through each api and perform GET and POST requests
for api in "${apis[@]}"; do
    # Use jq to extract the 'name' values and store them in an array called keyvaluemap_name
    keyvaluemaps=($(jq -r '.[]' "$DEST_DIR/${api}_api_kvm_details.json"))

    for keyvaluemap in "${keyvaluemaps[@]}"; do
        echo "keyvaluemap Name: $keyvaluemap"

        # Make a GET request using the 'keyvaluemap_name' as part of the URL
        curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apis/$api/keyvaluemaps/$keyvaluemap/entries" \
            --header "Authorization: Bearer $SOURCE_TOKEN" \
            -o "$DEST_DIR/${api}_api_${keyvaluemap}_kvm_entries_details.json"

        # Echo a message for each 'keyvaluemap_name'
        echo "Details for keyvaluemap name $keyvaluemap have been retrieved."

        entries=($(jq -r '.keyValueEntries[]' "$DEST_DIR/${api}_api_${keyvaluemap}_kvm_entries_details.json"))

        for entrie in "${entries[@]}"; do
            # Make a GET request using the 'keyvaluemap_name' as part of the URL
            curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apis/$api/keyvaluemaps/$keyvaluemap/entries/$entrie" \
                --header "Authorization: Bearer $SOURCE_TOKEN" \
                -o "$DEST_DIR/${api}_api_${keyvaluemap}_kvm_${entrie}_entries_details.json"

        done
    done
done

echo "api operations completed."
