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
  get_env_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/archiveDeployments" -H "Authorization: Bearer $SOURCE_TOKEN")

  # Save the response for the environment details to a file
  echo "$get_env_response" > "$DEST_DIR/${environment}_archiveDeployments_details.json"

  echo "Environment details saved to $DEST_DIR/${environment}_archiveDeployments_details.json"

  # Extract the 'archiveDeployment' values from the JSON response
  archiveDeployments=($(cat "$DEST_DIR/${environment}_archiveDeployments_details.json" | jq -r '.attribute[].archiveDeployment'))

  # Now you can loop through the 'archiveDeployment' values and perform an HTTP request for each 'archiveDeployment'
  for archiveDeployment in "${archiveDeployments[@]}"; do
    echo "archiveDeployment: $archiveDeployment"

    # Perform the HTTP request using the 'archiveDeployment' value
    curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/environments/$environment/archiveDeployments/$archiveDeployment" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${email}_developer_${archiveDeployment}_archiveDeployment_details.json"

    echo "Details for archiveDeployment $archiveDeployment have been retrieved."
  done
done

echo "Environment operations completed."
