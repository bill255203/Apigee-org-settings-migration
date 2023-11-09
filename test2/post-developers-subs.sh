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

# Extract the developer emails from the response using jq
emails=($(cat "$DEST_DIR/developers.json" | jq -r '.developer[].email'))

# Loop through the developer emails and retrieve detailed information for each
for email in "${emails[@]}"; do
  # Parse the subs as elements in an array
  IFS=$'\n' read -d '' -r -a subs < <(jq -r '.sub[].sub' "$DEST_DIR/${email}_subs.json")
  
  # Check if subs is empty or null and skip the loop if true
  if [ -z "$subs" ]; then
    echo "No subs found for email: $email. Skipping this loop."
    continue
  fi

  # Loop through the subs and make GET requests for each sub
  for sub in "${subs[@]}"; do
    # Create the JSON payload using data from the environment details file
    json_payload=$(cat "$DEST_DIR/${email}_${sub}_dev_sub_info.json")
    # Echo the JSON payload before making the POST request
    echo "JSON Payload:"
    echo "$json_payload"
    # Make the API call to get detailed information for the sub and save it to a file
    post_dev_sub_response=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/developers/$email/subscriptions/${sub}"  \
      -H "Authorization: Bearer $DEST_TOKEN" \
      -d "$json_payload" \
      --header 'Accept: sublication/json' \
      -H "Content-Type: sublication/json")
    # Save the response for the sub details to a file
    echo "$post_dev_sub_response" > "$DEST_DIR/${email}_${sub}_dev_sub_response.json"

    echo "sub details saved to $DEST_DIR/${email}_${sub}_dev_sub_response.json"
  done
  # Clean the subs array for this email
  unset subs
done

