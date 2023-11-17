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

# Parse the site names from the response
sites=($(cat "$DEST_DIR/sites.json" | jq -r '.[]'))

# Loop through each site and perform GET and POST requests
for site in "${sites[@]}"; do
  echo "Processing site: $site"

  # Make a GET request to get site details
  get_site_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/sites/$site/apicategories" -H "Authorization: Bearer $SOURCE_TOKEN")

  # Save the response for the site details to a file
  echo "$get_site_response" > "$DEST_DIR/${site}_site_apicategories_details.json"
  # Parse the apicategorie names from the response
  apicategorie_names=($(echo "$get_site_response" | jq -r '.[]'))

  for apicategorie in "${apicategorie_names[@]}"; do
    # Make a GET request to the apicategorie/{ks} endpoint for each apicategorie
    apicategorie_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/sites/$site/apicategories/$apicategorie" -H "Authorization: Bearer $SOURCE_TOKEN")

    # Save the response for the apicategorie to a file
    echo "$apicategorie_response" > "$DEST_DIR/${site}_site_${apicategorie}_apicategorie_details.json"
  done
done

echo "site operations completed."
