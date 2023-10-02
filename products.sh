#!/bin/bash

# Specify the source and destination project IDs
SOURCE_ORG="tw-rd-de-bill"
DEST_ORG="triple-voyage-362203"
DEST_ACCOUNT="YOUR_DESTINATION_ACCOUNT"
DEST_DIR="/Users/liaopinrui/Downloads/"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the initial API call to list developers and save the response to a file
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/developers" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/developers.json"

# Extract the developer emails from the response using jq
emails=($(cat "$DEST_DIR/developers.json" | jq -r '.developer[].email'))

# Loop through the developer emails and retrieve detailed information for each
for email in "${emails[@]}"; do
  echo "Retrieving developer information for email: $email"

  # Make the API call to get detailed information for the developer and save it to a file
  curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/developers/$email" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${email}_info.json"

  echo "Developer information for email $email has been retrieved."
done

echo "Listing API products..."
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apiproducts" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/api_products.json"
echo "API products list saved to $DEST_DIR/api_products.json"

# Function to retrieve details of an API product by name
get_api_product_details() {
  local product_name="$1"
  echo "Retrieving details for API product: $product_name..."
  curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apiproducts/$product_name" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${product_name}_details.json"
  echo "API product details saved to $DEST_DIR/${product_name}_details.json"
}

# Function to create or update an API product
create_or_update_api_product() {
  local product_name="$1"
  local product_details_file="$2"
  echo "Creating or updating API product: $product_name..."
  curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/apiproducts" \
    -H "Authorization: Bearer $SOURCE_TOKEN" \
    -o "$DEST_DIR/${product_name}_response.json" \
    -d @"$product_details_file" \
    -H "Content-Type: application/json"
  echo "API product creation or update response saved to $DEST_DIR/${product_name}_response.json"
}

# Parse the product names as elements in an array
IFS=$'\n' read -d '' -r -a product_names < <(jq -r '.apiProduct[].name' "$DEST_DIR/api_products.json")

# Loop through the product names
echo "List of API product names:"
for product_name in "${product_names[@]}"; do
  echo "$product_name"
done

# Loop through all API products and retrieve details
for product_name in "${product_names[@]}"; do
  get_api_product_details "$product_name"
done

# Authenticate with the destination account
gcloud auth login "$DEST_ACCOUNT"

# Get the OAuth 2.0 access token for the destination project
DEST_TOKEN=$(gcloud auth print-access-token)

# Loop through the developer emails again and create or update developers in the destination project
for email in "${emails[@]}"; do
  echo "Creating or updating developer for email: $email"

  # Load developer information from the JSON file
  developer_info=$(cat "$DEST_DIR/${email}_info.json")

  # Make a request to create or update the developer in the destination project
  curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/developers" -H "Authorization: Bearer $DEST_TOKEN" -o "$DEST_DIR/${email}_response.json" -d "$developer_info" -H "Content-Type: application/json"
  
  echo "Developer information for email $email has been created or updated in the destination project."
done

echo "Developer information retrieval and import completed."


# Loop through all API products and create or update them
for product_name in "${product_names[@]}"; do
  create_or_update_api_product "$product_name" "$DEST_DIR/${product_name}_details.json"
done

echo "API product operations completed."
