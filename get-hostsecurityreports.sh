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

# Make the initial API call to list hostSecurityReports and save the response to a file
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/hostSecurityReports" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/hostSecurityReports.json"

echo "hostSecurityReports list saved to $DEST_DIR/hostSecurityReports.json"

# Parse the hostSecurityReport names from the response
# hostSecurityReports=($(cat "$DEST_DIR/hostSecurityReports.json" | jq -r '.[]'))

# # Loop through each hostSecurityReport and perform GET and POST requests
# for hostSecurityReport in "${hostSecurityReports[@]}"; do
#   echo "Processing hostSecurityReport: $hostSecurityReport"

#   # Make a GET request to get hostSecurityReport details
#   get_hostSecurityReport_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/hostSecurityReports/$hostSecurityReport" -H "Authorization: Bearer $SOURCE_TOKEN")

#   # Save the response for the hostSecurityReport details to a file
#   echo "$get_hostSecurityReport_response" > "$DEST_DIR/${hostSecurityReport}_hostSecurityReport_details.json"

#   echo "hostSecurityReport details saved to $DEST_DIR/${hostSecurityReport}_hostSecurityReport_details.json"
# done

# echo "hostSecurityReport operations completed."
