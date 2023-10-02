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

envgroups=($(echo "$envgroups_json" | jq -c '.environmentGroups[]'))

# Loop through each environment group and create them in the destination project
for envgroup in "${envgroups[@]}"; do
  echo "Creating environment group in destination project..."

  # Make a POST request to create the environment group in the destination project
  create_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/envgroups" \
    -H "Authorization: Bearer $DEST_TOKEN" \
    -d "$envgroup" \
    -H "Content-Type: application/json")

  # Save the response for the created environment group to a file
  envgroup_name=$(echo "$envgroup" | jq -r '.name')
  echo "$create_response" > "$DEST_DIR/${envgroup_name}_create_response.json"

  echo "Environment group $envgroup_name created in the destination project."
done

echo "Environment group operations completed."
