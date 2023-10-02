#!/bin/bash

# Specify the source and destination project IDs
SOURCE_PROJECT_ID="tw-rd-de-bill"
DEST_PROJECT_ID="triple-voyage-362203"
DEST_ACCOUNT="YOUR_DESTINATION_ACCOUNT"  # Replace with your destination Google Cloud account
DEST_DIR="/Users/liaopinrui/Downloads/"  # Replace with your desired destination directory

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the initial API call to get the JSON response
response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_PROJECT_ID/apis?includeRevisions=true" \
  --header "Authorization: Bearer $SOURCE_TOKEN" \
  --header "Accept: application/json" \
  --compressed)

# Extract the names and revision numbers and loop through them for GET requests
for name in $(echo "$response" | jq -r '.proxies[] | .name'); do
  # Extract and sort the revision numbers numerically
  revisions=($(echo "$response" | jq -r --arg name "$name" '.proxies[] | select(.name == $name).revision[]' | sort -n))

  # Loop through the sorted revision numbers for each proxy name for GET requests
  for revision in "${revisions[@]}"; do
    echo "Proxy Name: $name"
    echo "Revision Number: $revision"

    # Construct the URL for the individual curl request to get the ZIP bundle
    url="https://apigee.googleapis.com/v1/organizations/$SOURCE_PROJECT_ID/apis/$name/revisions/$revision?format=bundle"

    # Perform the individual curl request to download the ZIP bundle to the specified directory
    curl -X GET "$url" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${name}_revision_${revision}.zip"
  done
done

# Now authenticate with the destination project
gcloud auth login "$DEST_ACCOUNT"

# Get the OAuth 2.0 access token for the destination project
DEST_TOKEN=$(gcloud auth print-access-token)

# Loop through the downloaded ZIP bundles and deploy them with POST requests
for name in $(echo "$response" | jq -r '.proxies[] | .name'); do
  # Extract and sort the revision numbers numerically
  revisions=($(echo "$response" | jq -r --arg name "$name" '.proxies[] | select(.name == $name).revision[]' | sort -n))

  # Loop through the sorted revision numbers for each proxy name for POST requests
  for revision in "${revisions[@]}"; do
    echo "Deploying Proxy Name: $name"
    echo "Revision Number: $revision"

    # Construct the URL for the individual curl request to deploy the ZIP bundle
    deploy_url="https://apigee.googleapis.com/v1/organizations/$DEST_PROJECT_ID/apis?name=${name}&action=import"

    # Perform the individual curl request to deploy the ZIP bundle
    curl -X POST "$deploy_url" -H "Authorization: Bearer $DEST_TOKEN" -H "Content-Type: application/octet-stream" --data-binary @"$DEST_DIR/${name}_revision_${revision}.zip"
  done
done
