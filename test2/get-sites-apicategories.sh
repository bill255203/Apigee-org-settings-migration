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
  echo "Processing environment: $environment"

  # Make a GET request to get environment details
  get_env_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/queries" -H "Authorization: Bearer $SOURCE_TOKEN")

  # Save the response for the environment details to a file
  echo "$get_env_response" > "$DEST_DIR/${environment}_queries_details.json"

  echo "Environment details saved to $DEST_DIR/${environment}_queries_details.json"

  # Extract the 'querie' values from the JSON response
  queries=($(cat "$DEST_DIR/${environment}_queries_details.json" | jq -r '.attribute[].querie'))

  # Now you can loop through the 'querie' values and perform an HTTP request for each 'querie'
  for querie in "${queries[@]}"; do
    echo "querie: $querie"

    # Perform the HTTP request using the 'querie' value
    curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/queries/$querie" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${email}_developer_${querie}_querie_details.json"

    echo "Details for querie $querie have been retrieved."
  done
done

echo "Environment operations completed."
