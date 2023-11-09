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

# Make the initial API call to list endpointAttachmentss and save the response to a file
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/endpointAttachments" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/endpts.json"

echo "endpointAttachments list saved to $DEST_DIR/endpts.json"

# Parse the endpointAttachments names from the response
endpointAttachments=($(cat "$DEST_DIR/endpts.json" | jq -r '.[]'))

# Loop through each endpointAttachments and perform GET and POST requests
for endpointAttachment in "${endpointAttachments[@]}"; do
  echo "Processing endpointAttachments: $endpointAttachment"

  # Make a GET request to get endpointAttachments details
  get_endpt_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/endpointAttachments/$endpointAttachment" -H "Authorization: Bearer $SOURCE_TOKEN")

  # Save the response for the endpointAttachments details to a file
  echo "$get_endpt_response" > "$DEST_DIR/${endpointAttachment}_endpt_details.json"

  echo "endpointAttachments details saved to $DEST_DIR/${endpointAttachment}_endpt_details.json"
done

echo "endpointAttachments operations completed."
